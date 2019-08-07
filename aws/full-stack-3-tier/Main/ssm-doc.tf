resource "aws_ssm_document" "life_ssm_command" {
  name          = "ssm_asg_lifecycle_hook"
  document_type = "Command"

  content = <<DOC
  {
    "schemaVersion": "1.2",
    "description": "Backup logs to S3",
    "parameters": {
       "ASGNAME":{
        "type":"String",
        "description":"Auto Scaling group name"
      },
       "LIFECYCLEHOOKNAME":{
        "type":"String",
        "description":"LIFECYCLEHOOK name"
      },
       "BACKUPDIRECTORY":{
        "type":"String",
        "description":"BACKUPDIRECTORY localtion in server"
      },
       "S3BUCKET":{
        "type":"String",
        "description":"S3BUCKET backup logs"
      },
       "SNSTARGET":{
        "type":"String",
        "description":"SNSTARGET"
      }
    },
    "runtimeConfig": {
      "aws:runShellScript": {
        "properties": [
          {
            "id": "0.aws:runShellScript",
            "runCommand": [
              "",
              "#!/bin/bash ",
              "INSTANCEID=$(curl http://169.254.169.254/latest/meta-data/instance-id)",
              "HOOKRESULT='CONTINUE'",
              "REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')",
              "dt=*.`date '+%Y-%m-%d'`.log",
              "tf=`date '+%Y-%m-%d'`",
              "MESSAGE=''",
              "",
              "if [ -d \"{{BACKUPDIRECTORY}}\" ];",
              "then",
              "for i in `find \"{{BACKUPDIRECTORY}}\" -name \"$dt\"`; do echo $i; sudo /usr/local/bin/aws s3 cp $i s3://\"{{S3BUCKET}}\"/\"$tf\"/\"$INSTANCEID\"/; done",
              "else",
              " MESSAGE= \"{{BACKUPDIRECTORY}}\" directory Not exits in this server ",
              "echo $MESSAGE",
              "fi",
              "",
              "/usr/local/bin/aws sns publish --subject ' Report-Logs_backup-{{ASGNAME}} ' --message \"$MESSAGE\"  --target-arn {{SNSTARGET}} --region $${REGION}",
              "/usr/local/bin/aws autoscaling complete-lifecycle-action --lifecycle-hook-name {{LIFECYCLEHOOKNAME}} --auto-scaling-group-name {{ASGNAME}} --lifecycle-action-result $${HOOKRESULT} --instance-id $${INSTANCEID}  --region $${REGION}"
            ]
          }
        ]
      }
    }
  }
  DOC
}