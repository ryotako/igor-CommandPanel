#!/bin/bash

echo "#pragma ModuleName=CommandPanel" > ./CommandPanel.ipf

cat ./source/*.ipf ./igor-writer/source/*.ipf \
  | sed s/$'\t'MenuItem/$'\t'CommandPanel#MenuItem/ \
  | sed '/^#include/d
        s/^Function/static Function/
        /Writer_/s/^static Function/Function/
        /CommandPanel_/s/^static Function/Function/
        /ModuleName/d
        s/Q, MenuCommand/Q, CommandPanel#MenuCommand/'\
  >> ./CommandPanel.ipf

