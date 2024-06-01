# やねうら王 on Apple Watch

`nn.bin`は独自に学習した `halfkp_128x2-32-32` 型。
nnue-pytorchにより独自学習した。
shogi_hao_depth9データセットを利用。1008ファイルを学習に、8ファイルをvalidationに使用。
batch size=16384
中断をはさみ19000+38000epoch学習した。1epoch=61step。3477000step相当。
学習器がlrを上げた時点でモデルが壊れたので、その直前のモデルになる。
val loss=0.0663
