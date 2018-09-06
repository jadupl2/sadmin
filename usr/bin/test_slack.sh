#!/usr/bin/env sh
#===================================================================================================
#
SCRIPT="/sadmin/usr/bin/test_and_examples/test_slack_message.sh"
WHOOK="https://hooks.slack.com/services/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"
$SCRIPT -c sadmin_warning -m "`date +%T` - Test SADM Warning Message" -u batservers -h $WHOOK
sleep 5
#
WHOOK="https://hooks.slack.com/services/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"
$SCRIPT -c sadmin_error -m "`date +%T` - Test SADM SADMIN Error Message" -u batservers -h $WHOOK
sleep 5
#
WHOOK="https://hooks.slack.com/services/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"
$SCRIPT -c sadmin -m "`date +%T` - Test SADMIN Message" -u batservers -h $WHOOK
#
