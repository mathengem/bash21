**Prerequisites:**
```
sudo apt install base58
sudo apt install xxd
sudo apt install qrencode
sudo apt install imagemagick
```


**Usage:**

Make the script executable for the current user:
`chmod u+x paperwallet.sh`

Run it:
`./paperwallet.sh`

**Execution results:**
1. A file keys.gpg which includes the sensitive data (keys etc.) of the wallet. The file is encrypted with the password that you set at execution time.
2. A file legacy_address.png which displays a QR code for the wallet's legacy (P2PKH) address.
3. A file segwit_address.png which displays a QR code for the wallet's segwit (P2WPKH-P2SH) address.
4. A file addresses.txt which includes the addresses in .txt format.
5. A file wallet.pdf which includes the QR codes for the legacy address and the WIF.

**keys.gpg file format:**

```
Entropy: D_}L1jJie.'&p~@GS<@/~Yr;?uj69lm!vT^V`h1uxW!nhYU"'D>H@`7NP]#e7<?{
PK: c46b641982fd74f10a1607d01e70e4d4c7a5aed2c01c7b09bd66044ce26f0913
WIF: L3oXPPp62gS6NtxopBGoGDhvs6g4ovGp4oX34nLXa566d6qNSMyJ
Public Key: 048f92eb77547bc8b1f5e1e62b683399d75bfc1e98621fef0e253f36baf27891d8c07e72e095cd5b298bc94182a050e80b66a64d0f76967bd1d44077430289dae4
Compressed Public Key: 028f92eb77547bc8b1f5e1e62b683399d75bfc1e98621fef0e253f36baf27891d8
HASH160: 9ba03f824e7883027d07fb15a627a82a897195ba
Legacy Address: 1FBshy1TaRCoWM2ChiJ6dyDZdPmEfDAHHq
Segwit Address: 37gzjcd6wssRB2igUWDYNB4cp546ksFXXo
```

**Some notes:**

The entropy is produced from `/dev/urandom`.
