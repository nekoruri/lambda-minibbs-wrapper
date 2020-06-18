# MiniBBSをAWS Lambdaで動かすハンドラ関数

# DESCRIPTION

CGI RESCUE様の簡易ＢＢＳ（MiniBBS）をAWS Lambda上で動かすためのハンドラ関数です。

同じ感じで、Perl時代のCGI資産をそのままAWS Lambda+EFSの環境で動かせると思うので、
サーバーレスへの移行導入の参考にしてください。

[en] This is a handler function that runs CGI scripts on AWS Lambda.

# HOWTO

## Perlランタイム

perl-5-30-runtimeをレイヤーに食わせてください。

* https://github.com/shogo82148/p5-aws-lambda

## Perlモジュール

CGI::Emulate::PSGIとCGI::Compileが必要なので、
以下のように作ったZIPをレイヤーに食わせてください。

```
docker run --rm \
    -v $(pwd):/var/task \
    -v $(pwd)/opt/lib/perl5/site_perl:/opt/lib/perl5/site_perl \
    shogo82148/p5-aws-lambda:build-5.30 \
    cpanm --notest --no-man-pages CGI::Emulate::PSGI CGI::Compile
cd opt
zip -9 -r ../CGI-Emulate-PSGI.zip .
```

## データ保存先

データはEFS上で共有することを想定しています。
適当に設定してください。

## スクリプト本体

MiniBBS本体(minibbs.cgi)とjcode.plは、
CGI RESCUE様のウェブサイトからダウンロードしてください。

* https://www.rescue.ne.jp/cgi/minibbs1/

* 1行目のshebangを/usr/bin/perlに変更
* $reload $modoru $tmp_dir を設定

デプロイ用ZIPの作成をする build_zip を同梱しています。

# しくみ

* AWS::Lambda
  * Perlランタイムを立ち上げ
  * https://github.com/shogo82148/p5-aws-lambda
* handler.pl
  * AWS::Lambda::PSGIで関数をPlackアプリに変換
* Plack::App::WrapCGI
  * PlackからCGIにインターフェース変換
  * 内部でCGI::Emulate::PSGIを使用
  * CGI::CompileはLambda環境で動かないため(読み込まれるので導入は必要)、forkして実行
* minibbs.cgi
  * MiniBBS ( https://rescue.ne.jp/cgi/minibbs1/ )
  * EFS上にデータファイル設置

# 他のCGIスクリプトで使う

CGIスクリプトがPerlで書かれている必要は無いので、
handler.pl内の minibbs.cgi を変更すればどの言語でも動作します。

ただし、AWS Lambdaの実行環境に言語環境やライブラリが無いものは一緒にデプロイするか、
EFS上にあらかじめ設置する必要があります。

# LICENSE

MIT license (c) 2020 NAKAYAMA Masahiro <aki@nekoruri.jp>

当初はGPLでしたがPlackのコードを含まなくなったので変更しました。

