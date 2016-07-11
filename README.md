# igor-CommandPanel

## 概要
CommandPanel.ipfはIgor Proに新しいコマンド入力インターフェイスを提供します．

![](https://github.com/ryotako/igor-CommandPanel/wiki/Demo.gif)

- 入力を実行する前にbash風のエイリアス展開，ブレース展開，パス名展開を行います．
- 入力に応じて操作関数名・関数名補完，パス名補完を行います．
- 出力結果を，指定した文字列で検索(その文字列を含むものに絞込み)することができます．

## 展開
`Enter`を押すと入力を展開して実行します．また，何も入力していない状態で`Enter`を押すとコマンドの実行履歴を表示します．
### エイリアス展開
コマンドの別名を登録します．
```
alias cp=Duplicate
cp/O :wave :wave_copy // 実際には Duplicate/O :wave :wave_copy が実行されます．
```
### ブレース展開
``` 
NewDataFolder sample{A,B}_{1..2}
```
以下のように展開されます．
```
NewDataFolder sampleA_1
NewDataFolder sampleA_2
NewDataFolder sampleB_1
NewDataFolder sampleB_2
```
### パス名展開
パスの一部にワイルドカード*を使用することができます．
以下のコマンドは，ひとつ下のフォルダにあるwaveで始まるコマンドをすべて表示します．
```
Display
AppendToGraph :*:wave*
```

### 括弧の省略
各行で最初に使うユーザ定義関数について，()の入力を省略できます．
関数の引数が文字列ひとつだけの場合，""の入力も比較できます．
```
DoSomething()
CompareSomething(a,abs(b))
PrintSomething("test")
```
これらは以下のように呼び出せます．
```
DoSomething
CompareSomething a,abs(b) // 最初の関数以外の()は省略できません．
PrintSomething test
```

## 補完
`Shift`と`Enter`を同時に押すと，現在の入力に応じた補完が行われます．
操作関数名・関数名補完のほか，`:`あるいは`root:`で始まるフレーズをパス名として補完します．

また，何も入力していない状態で`Shift`と`Enter`を同時に押すと出力結果で入力を置き換えることができます．

## 絞込み
半角空白` `で始まる文字列を入力した状態で`Shift`と`Enter`を同時に押すと，現在の出力結果をその文字列を含むものに絞り込みます．
複数の単語(正規表現)を半角空白` `で区切って並べるとAND検索になります．
