# Inspired by woocommerce/wooocommerce-test-reports.
#
# This script combines a previous Allure report with a new one to create history trend.
#
# The following environment variables must be set in order to use this script:
# - ALLURE_RESULTS_PATH
#   This is the base path for the Allure data path (eg. repo_root/allure_results)
# - CURRENT_REPORT_PATH
#   This is the path for the existing report, if any. (eg. repo_root/current_allure_report)
# - REPORT_PATH
#   This is the output path for the new report. (eg. docs/report)
#
#!/usr/bin/env bash

if [[ -d "$CURRENT_REPORT_PATH" ]]; then
    echo "Copying report history to new Allure results data..."
    # Make the "history" directory in the newest Allure results directory.
    mkdir -p $ALLURE_RESULTS_PATH/history
    # Copy over contents of the "history" directory from the existing report.
    cp -R $CURRENT_REPORT_PATH/history/ $ALLURE_RESULTS_PATH/history
else 
    echo "No prior report found. Creating directory..."
    # Fresh run. Allure will generate report without considering history.
    mkdir -p $REPORT_PATH
fi

echo "Generating report..."
allure generate --clean $ALLURE_RESULTS_PATH --output $REPORT_PATH
echo "Finished generating report."
