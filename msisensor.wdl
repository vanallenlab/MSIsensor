workflow MSI_sensor {
	String pair_id
    File tumor_bam
	File tumor_bai
	File? normal_bam
	File? normal_bai

	String? reference = "hg19"
	File hg19_scan = "gs://fc-f36b3dc8-85f7-4d7f-bc99-a4610229d66a/msi_sensor/hg19_msisensor_scan.list"
	File hg38_scan = "gs://fc-f36b3dc8-85f7-4d7f-bc99-a4610229d66a/msi_sensor/hg38_msisensor_scan.list"
    File reference_microsatellites_scan = if reference == "hg38" then hg38_scan else hg19_scan

	File interval_list
	Boolean convert_interval_list_to_bed = true

	Int? msi_status_threshold = 10

    Int? smRAM = 2
    Int? smSSD = 25
    Int? lgRAM = 7
    Int? lgSSD = 100
    Int? preemptible = 3

    String? docker_tag = "0.5"

    File monitoring_script = "gs://fc-f36b3dc8-85f7-4d7f-bc99-a4610229d66a/monitoring_script.sh"

    meta {
        author: "Brendan Reardon"
        email: "breardon@broadinstitute.org"
    }

    if (convert_interval_list_to_bed) {
        call IntervalListToBed {
            input:
                interval_list=interval_list,
                RAM=smRAM,
                SSD=smSSD,
                preemptible=preemptible
        }
    }

    File? msi_sensor_intervals = if (convert_interval_list_to_bed) then IntervalListToBed.bed else interval_list

    call MSIsensor {
        input:
            pair_id=pair_id,
            tumor_bam=tumor_bam,
            tumor_bai=tumor_bai,
            normal_bam=normal_bam,
            normal_bai=normal_bai,
            intervals=msi_sensor_intervals,
            microsatellites_list=reference_microsatellites_scan,
            msi_status_threshold=msi_status_threshold,
            RAM=lgRAM,
            SSD=lgSSD,
            preemptible=preemptible,
            docker_tag = docker_tag
    }

    output {
        File msisensor_microsatellites_list = MSIsensor.microsatellites_list
        File msisensor_msi_score = MSIsensor.msi_score
        File msisensor_read_count_distribution = MSIsensor.read_count_distribution
        File msisensor_somatic_sites = MSIsensor.somatic_sites
        File? msisensor_germline_sites = MSIsensor.germline_sites
    }
}

task IntervalListToBed {
    File interval_list

	Int? RAM
	Int? SSD
	Int? preemptible

    command {
        /./gatk/gatk IntervalListToBed -I ${interval_list} -O bedintervals.bed
    }

    runtime {
        docker: "broadinstitute/gatk:4.0.8.1"
        memory: RAM + " GB"
        disks: "local-disk " + SSD + " SSD"
        preemptible: preemptible
    }

    output {
        File bed="bedintervals.bed"
    }
}

task MSIsensor_scan {
    File reference_fasta
	File reference_index
	File reference_dict

	Int? RAM
	Int? SSD
	Int? preemptible

	String? docker_tag

	File monitoring_script

    command <<<
        chmod u+x ${monitoring_script}
        ${monitoring_script} > monitoring.log &

        msisensor scan -d ${reference_fasta} -o microsatellites.list
    >>>

	runtime {
        docker: "vanallenlab/msisensor:" + docker_tag
        memory: RAM + " GB"
        disks: "local-disk " + SSD + " SSD"
        preemptible: preemptible
    }

    output {
        File microsatellites_list="microsatellites.list"
        File monitoring_log="monitoring.log"
    }

}

task MSIsensor {
    String pair_id
    File tumor_bam
    File tumor_bai
    File? normal_bam
    File? normal_bai

    File microsatellites_list
	File? intervals

	Int? msi_status_threshold
	Boolean paired = defined(normal_bam)

    Int? RAM
	Int? SSD
	Int? preemptible

	String? docker_tag

	command <<<
        if [ "${paired}" == "true" ]; then
            args="-n ${normal_bam} -t ${tumor_bam}"; else
            args="-t ${tumor_bam}";
        fi

        echo "Evaluating microsatellites in sample"
        msisensor msi -d ${microsatellites_list} $args -e ${intervals} -o ${pair_id}

        sed -n "2p"  ${pair_id} | awk { print $3 } > output.txt
	>>>

	runtime {
        docker: "vanallenlab/msisensor:" + docker_tag
        memory: RAM + " GB"
        disks: "local-disk " + SSD + " SSD"
        preemptible: preemptible
    }

	output {
	    Float percent_altered_somatic_sites = read_float("output.txt")
        String msi_status = if (percent_altered_somatic_sites >= msi_status_threshold) then "MSI" else "MSS"

        File msi_score="${pair_id}"
        File read_count_distribution="${pair_id}_dis_tab"
        File somatic_sites="${pair_id}_somatic"
        File? germline_sites="${pair_id}_germline"
	}
}