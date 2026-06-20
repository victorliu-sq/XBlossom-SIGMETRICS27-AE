#!/usr/bin/env bash
set -euo pipefail

echo "[Datasets] Download Realworld Datasets"

DATASETS_DIR="${PROJECT_DIR}/data/realworld_datasets"
mkdir -p ${DATASETS_DIR}

#REALWORLD_DATASETS_LINK="https://1drv.ms/f/c/853ed58dd8aaea4c/Et7Vix8POPRFsemfl3CF5ZQBnU_FMmNye1_IWUd1-Ihqmw?e=T43icB"
pushd ${DATASETS_DIR} >/dev/null

# Download Amazon Realworld Dataset

download_and_extract_dataset() {
  local DATASET_NAME="$1"
  local URL="$2"
  local DATASET_STAMP=".stamp.${DATASET_NAME}.Dataset"
  local TARBALL="${DATASET_NAME}.tar.gz"
  local PY_SCRIPT="${EXPR_DIR}/datasets/download_dataset.py"

  if [[ ! -f "${DATASET_STAMP}" ]]; then
    echo "[download] Downloading ${DATASET_NAME} ..."
    # Download tarball
    # wget -O "${TARBALL}" "${URL}"
    conda run -n xb-env --live-stream python3 "${PY_SCRIPT}" "${URL}" "${TARBALL}"

    # Extract
    tar -xzf "${TARBALL}"
    # Clean up tarball
    rm -f "${TARBALL}"
    # Mark as downloaded
    touch "${DATASET_STAMP}"
    echo "[download] ${DATASET_NAME} done!"
  else
    echo "[download] ${DATASET_NAME} already exists, skipping download"
  fi
}

download_and_extract_dataset "Amazon" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/EZZTvXC9zd5HjVoCnAibH5wBo0KtR5vDG1d-0abp_uZ_8g?e=H9eK9C"
download_and_extract_dataset "Google" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/Ee_6P-oRG_xKiZXQ5w-WTLsBvp11Sk8zk8X5vdYu0FX2hQ?e=MoETaO"
download_and_extract_dataset "HiggsNets" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/EZcOKTnPY1BInFFL2BaEoqQB43mO40xMWJ9lxqY7jfBjGA?e=a7TGw7"
download_and_extract_dataset "Hyperlink" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/ETwRfOoL13JAhQ1V_REMJ3wB1m-PEyMWFncWRLrDxbovHw?e=RoNIGv"
download_and_extract_dataset "Livejournal" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/EaXr1z5q5K9FsnzlFPahSJMB6ck7MVFvFCMRAeOxAoykRA?e=MJExXI"
download_and_extract_dataset "Patent" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/EQSrGkyeRh1CsLgyaxJ4H3UB-iG1w3oTmS2B81MmGdOh6w?e=xY3uy5"
download_and_extract_dataset "Stackoverflow" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/Ef2RTVmFhcBLgWytTJR3PsEBgYklMW9TtLOJ61h4I_7qsA?e=QLgbg6"
download_and_extract_dataset "Twitch" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/EaIlen5k82BProH8qTBb_84BxrdCnDXf-IH7wiauH8LZ6g?e=sbUtrF"
download_and_extract_dataset "Wikipedia" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/EYOrXZxnvxVEnDu-VIiQ_BgBQAN_9qx-zBSMZGaxLLuvaw?e=o4wYwk"
download_and_extract_dataset "Youtube" "https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/EVB5QeGhbwlCttinqXQZSQ4BRHzLHY6zDmqsZQ_1kUG5EQ?e=9JFckg"

#DATASET_STAMP=".${DATASET_NAME}.Dataset"
#if [[ ! -f  "${DATASET_STAMP}" ]]; then
#  TARBALL="${DATASET_NAME}.tar.gz"
#  URL="https://my.microsoftpersonalcontent.com/personal/853ed58dd8aaea4c/_layouts/15/download.aspx?UniqueId=cd3359e5-6fb5-4edf-82de-66af6b5a9e03&Translate=false&tempauth=v1e.eyJzaXRlaWQiOiJmNjJkYjQzMS1lMjA5LTQ2ZjgtOWFhYi1kYjU1ODUxY2RmMTEiLCJhcHBpZCI6IjAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDA0ODE3MTBhNCIsImF1ZCI6IjAwMDAwMDAzLTAwMDAtMGZmMS1jZTAwLTAwMDAwMDAwMDAwMC9teS5taWNyb3NvZnRwZXJzb25hbGNvbnRlbnQuY29tQDkxODgwNDBkLTZjNjctNGM1Yi1iMTEyLTM2YTMwNGI2NmRhZCIsImV4cCI6IjE3NTg5MTMyMTMifQ.VeATHUzzTm1mnI23h_uWcNC3m-g5NUPyGOmzqSbUNk-jrlWZHoi5x-35kBl4JE5SoGJXk2GNty9Bp1qEIx2TsbSKdhNydva_uySCKyIu0UQEi0_qAQkYprkV5gDvfcWaQ39txsxkBFemLNKg8yZ-4r0vxNtK1kn_1H1oN27r4MFlSZcYYCqgm7yFE3jLM90CZdq3lZbAiDKwoN2s4XGtU3f1XluNLlVdMBdGWYyrw0JTFMlJA1gt3cWwWyXWPpUUOgjwbEnRh1BzhE4Y0MHzcs9pf-wb2Ja5t27aa3aFJcAihCvXjnpLQ_4xZ4C0w7eFM1WtPs7y-uzbndCsG_HqFQzikXDsxc0a6S52m--9jnX0dZtlsKuGmueTtfE977fQQtrmSPSN7NWDEKGk905LevNw0l4VIyixYfFChrp54oI.qsaoF3fR6YVG_3n-ln8aq83989cxVn1sp26alju3zGw&ApiVersion=2.0&AVOverride=1"
#  download "$URL" "$TARBALL"
#  #wget "$URL"
#  tar -xzf "$TARBALL"
#  rm ${TARBALL}
#  touch $DATASET_STAMP
#else
#  echo "[download] ${DATASET_NAME} already exists, skipping download"
#fi

popd >/dev/null