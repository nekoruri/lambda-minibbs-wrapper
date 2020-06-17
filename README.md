# MiniBBSをAWS Lambdaで動かすハンドラ関数

# DESCRIPTION

CGI RESCUE様の簡易ＢＢＳ（MiniBBS）をAWS Lambda上で動かすためのハンドラ関数です。

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

* 1行目のshebangを/usr/bin/perlに変更
* $reload $modoru $tmp_dir を設定

* https://www.rescue.ne.jp/cgi/minibbs1/

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


# LICENSE

Plackのコードを含んでいるためGPLです。

