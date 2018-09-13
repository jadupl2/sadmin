#!/usr/bin/env sh
#===================================================================================================
#
SCRIPT="/sadmin/usr/bin/test_and_examples/slack_test/send_slack_message.sh"
WHOOK="https://hooks.slack.com/services/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"
$SCRIPT -c sadm_info -m "`date +%T` - Test sadm_info Message" -u batservers -h $WHOOK
sleep 5
#
WHOOK="https://hooks.slack.com/services/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"
$SCRIPT -c sadm_dev -m "`date +%T` - Test sadm_dev Message" -u batservers -h $WHOOK
sleep 5
#
WHOOK="https://hooks.slack.com/services/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"
$SCRIPT -c sadm_prod -m "`date +%T` - Test sadm_prod Message" -u batservers -h $WHOOK
#
