# [Xeldorado Protocol](nft.xeldorado.live)
Open source implementation of Xeldorado Protocol - The NFT DEX. It contains smart contracts for Xeldorado Protocol : Xeldorado Factory and Route.

## Documentation

What we do: [Understand](https://nft.xeldorado.live/index.html#xeldoradoprotocol)

<!-- <a href="https://nft.xeldorado.live/index.html#xeldoradoprotocol" target="_blank"><img src="https://nft.xeldorado.live/images/logo.png" width="150" height="30"/></a> -->

White paper for Xeldorado Protocol is currently under development.

## Licensing

The primary license for Xeldorado Contracts V1 is the Business Source License 1.1 (`BUSL-1.1`), see [`LICENSE`](./LICENSE). 

<h3>
    
```diff
!!! Overall this repository is not available for production use currently !!!
```

</h3>

### Exceptions

- All files in `contracts/interfaces/` are licensed under `GPL-2.0-or-later` (as indicated in their SPDX headers), see [`contracts/interfaces/LICENSE`](./contracts/interfaces/LICENSE)
- Several files in `contracts/libraries/` are licensed under `GPL-2.0-or-later` (as indicated in their SPDX headers), see [`contracts/libraries/LICENSE`](contracts/libraries/LICENSE)
- All files in `contracts/test` remain unlicensed.

## Community

<a href="https://discord.gg/ExMb82zpnB" target="_blank"><img src="https://nft.xeldorado.live/images/discord.png" width="80" height="80"/></a>&emsp;&emsp;&emsp;
<a href="https://t.me/xeldorado" target="_blank"><img src="https://nft.xeldorado.live/images/telegram.png" width="80" height="80"/></a>&emsp;&emsp;&emsp;
<a href="https://twitter.com/RealXeldorado" target="_blank"><img src="https://nft.xeldorado.live/images/twitter.png" width="80" height="80"/></a>&emsp;&emsp;&emsp;
<a href="https://www.reddit.com/r/Xeldorado" target="_blank"><img src="https://nft.xeldorado.live/images/reddit.png" width="80" height="80"/></a>

## Responsible disclosure

At Xeldorado, we consider the security of our systems a top priority. But even putting top priority status and maximum effort, there is still possibility that vulnerabilities can exist. 

In case you discover a vulnerability, we would like to know about it immediately so we can take steps to address it as quickly as possible.  

If you discover a vulnerability, please do the following: 

    E-mail your findings to xeldorado.nft@gmail.com; 

    Do not take advantage of the vulnerability or problem you have discovered; 

    Do not reveal the problem to others until it has been resolved; 

    Do not use attacks on physical security, social engineering, distributed denial of service, spam or applications of third parties; and 

    Do provide sufficient information to reproduce the problem, so we will be able to resolve it as quickly as possible. Complex vulnerabilities may require further explanation so we might ask you for additional information. 

We will promise the following: 

    We will respond to your report within 3 business days with our evaluation of the report and an expected resolution date; 

    If you have followed the instructions above, we will not take any legal action against you in regard to the report; 

    We will handle your report with strict confidentiality, and not pass on your personal details to third parties without your permission; 

    If you so wish we will keep you informed of the progress towards resolving the problem; 

    In the public information concerning the problem reported, we will give your name as the discoverer of the problem (unless you desire otherwise); and 

    As a token of our gratitude for your assistance, we offer a reward for every report of a security problem that was not yet known to us. The amount of the reward will be determined based on the severity of the leak, the quality of the report and any additional assistance you provide.  

## Remarks

Currently we won't be having any exchange token but the core contract has support for discounted fees based on the number of exchange tokens owned. This is done to ensure smooth future integration of exchange token next year after our protocol gains some traction.
