#!/bin/bash

cat ./CommandPanel_Menu.ipf\
  ./CommandPanel_Interface.ipf\
  ./CommandPanel_Execute.ipf\
  ./CommandPanel_Expand.ipf\
  ./CommandPanel_Complete.ipf\
  ./igor-writer/writer.string.ipf\
  ./igor-writer/writer.wave.ipf\
  | sed s/$'\t'MenuItem/$'\t'CommandPanel#MenuItem/ \
  | sed '/^#include/d
         /CommandPanel_/!s/^Function/static Function/
         /ModuleName/d
         s/FUNCREF id/FUNCREF CommandPanel_ProtoTypeFunc1/
         s/FUNCREF return/FUNCREF CommandPanel_ProtoTypeFunc2/
         s/Q, MenuCommand/Q, CommandPanel#MenuCommand/'\
  > ./tmp.ipf

cat ./CommandPanel_Header.ipf\
  ./tmp.ipf\
  > ./CommandPanel.ipf

rm ./tmp.ipf
