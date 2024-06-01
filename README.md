# やねうら王 on Apple Watch

# モデルについて
nnue-pytorchにより独自学習した。
shogi_hao_depth9データセットを利用。1008ファイルを学習に、8ファイルをvalidationに使用。
batch size=16384

形式は標準NNUE (halfkp_256x2-32-32)。3982899step学習した。val loss=0.0619。
lrが下がりきっていないが、lr6.1e-5まで進んでおり、ほぼval lossに変化のない状態で学習を終了した。
Apple Watchの探索速度を想定したノード数制限で、1手1秒の場合に水匠5に対してレート+45。
