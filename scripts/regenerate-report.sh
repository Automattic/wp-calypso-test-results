# Inspired by woocommerce/wooocommerce-test-reports.
#
# This script combines a previous Allure report with a new one to create history trend.
#
# The following environment variables must be set in order to use this script:
# - ALLURE_RESULTS_PATH
#   Path which holds the Allure results (eg. repo_root/allure_results)
# - HISTORY_PATH
#   Path which holds the history trend. (eg. repo_root/history)
# - REPORT_PATH
#   Path to which the new report will be written to. (eg. docs/report)
#
#!/usr/bin/env bash

if [[ -d "${{ env.HISTORY_PATH }}" ]]; then
    echo "Copying report history to new Allure results data..."
    # Make the "history" directory in the newest Allure results directory.
    mkdir -p ${{ env.ALLURE_RESULTS_PATH }}/history

    # Copy over contents of the "history" directory from the existing report.
    # The trailing /* is important; without it, the directory is copied instead of the JSON files.
    cp -R ${{ env.HISTORY_PATH }}/* ${{ env.ALLURE_RESULTS_PATH }}/history
else 
    # Fresh run. Allure will generate a fresh report.
    echo "No prior report found."
fi

mkdir -p ${{ env.REPORT_PATH }}

echo "Generating report..."
allure generate --clean ${{ env.ALLURE_RESULTS_PATH }} --output ${{ env.REPORT_PATH }}
echo "Finished generating report."
