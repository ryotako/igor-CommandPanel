#!/bin/bash
cd $(dirname $0)

echo "#pragma ModuleName=CommandPanel" > ./CommandPanel.ipf

cat ./source/*.ipf ./igor-writer/writer.ipf \
  | sed s/$'\t'MenuItem/$'\t'CommandPanel#MenuItem/ \
  | sed '/^#include/d
         /CommandPanel_/!s/^Function/static Function/
         /ModuleName/d
         s/FUNCREF id/FUNCREF CommandPanel_ProtoTypeFunc1/
         s/FUNCREF return/FUNCREF CommandPanel_ProtoTypeFunc2/
         s/Q, MenuCommand/Q, CommandPanel#MenuCommand/'\
  >> ./CommandPanel.ipf

