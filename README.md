# igor-CommandPanel

CommandPanel.ipf provides an alternative commandline interface for Igor Pro．

![Demo](https://github.com/ryotako/igor-CommandPanel/blob/master/Demo%20.gif)

## Features
- bash-like alias expansion, brace expansion, and pathname expansion.
- copmplete operation, function, data folder, wave, variable, string name.
- filtering the output with words (regular expressions)．

## Expansion
Execute commands by pressing `Enter`．If one puss `Enter` without inpupt, the command history is displayed．
### Alias Expansion
```
alias cp=Duplicate
cp/O :wave :wave_copy
```
### Brace Expansion
``` 
NewDataFolder sample{A,B}_{1..2}
```
This is expanded as follows.
```
NewDataFolder sampleA_1
NewDataFolder sampleA_2
NewDataFolder sampleB_1
NewDataFolder sampleB_2
```
### Pathname expansion
You can use wildcard * in pathnames.
```
Display
AppendToGraph :*:wave*
```

### Parenthesis completion
You can omit () at the first user function in each line.
```
DoSomething()
CompareSomething(a,abs(b))
PrintSomething("test")
```
These functions can be called as belows.
```
DoSomething
CompareSomething a,abs(b) // You cannot omit () at the second function.
PrintSomething test       // When the function take just a string parameter, you can omit "" too. 
```

## Completion
Your input is completed by pushing `Shift+Enter`.
Thes procedure complete operation and function name. Words beginning with : are completed as pathnames.
When you push `Shift+Enter` without input, the output or complete candidates are scrolled down. (You can scroll up with `Alt+Enter` in Mac.)

## Filtering
You can filtering the outputs or completion candidates by pushing `Shift+Enter` with an input beginning with a blank character ` `. 
Regular expressions can be used for this filtering.
