# Inspired by woocommerce/wooocommerce-test-reports.
#
# This script combines a previous Allure report with a new one to create history trend.
#
# The following environment variables must be set in order to use this script:
# - ALLURE_RESULTS_DATA_BASE_PATH
#   This is the base path for the Allure data path (eg. repo_root/data)
# - LATEST_ALLURE_RESULT
#   This is the latest set of results. (eg. 125/)
# - REPORT_PATH
#   This is the output path for the report. (eg. docs/report)
#
#!/usr/bin/env bash

if [[ ! -d "$ALLURE_RESULTS_DATA_BASE_PATH/$LATEST_ALLURE_RESULT" ]]; then
    echo "No Allure data found under $ALLURE_RESULTS_DATA_BASE_PATH/$LATEST_ALLURE_RESULT."
    exit 1
fi

if [[ -d "$REPORT_PATH" ]]; then
    echo "Copying report history to new Allure results data..."
    mkdir -p $ALLURE_RESULTS_DATA_BASE_PATH/$LATEST_ALLURE_RESULT/history
    cp -R $REPORT_PATH/history/ $ALLURE_RESULTS_DATA_BASE_PATH/$LATEST_ALLURE_RESULT/history
else 
    echo "No prior report found. Creating directory..."
    mkdir -p $REPORT_PATH
fi

echo "Generating report..."
allure generate --clean $ALLURE_RESULTS_DATA_BASE_PATH/$LATEST_ALLURE_RESULT --output $REPORT_PATH