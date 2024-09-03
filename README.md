1. open_fee_bps, 开仓费          0.001
2. decrease_fee_bps,  关仓费     0.001
3. rebate_fee, 邀请人返佣，被邀请人减免
    交易额 * 0.001 * 0.05
4. LP 费用, compute_rebase_fee_rate
        deposit, 
        withdraw
            * 如果有利于仓位平衡的情况下, 返回 model.base ( 1% )
            * model.base + (ratio - target_ratio) * model.multiplier (0.0008)
        a. 可以用比较大金额的代币去测试

5. funding_fee(动态)
    symbol.acc_funding_rate(累计费率)
    funding_fee_value = position_size * (funding_rate - last_funding_rate) 
    funding_fee = (2000 - 1000) * position.position_size

6. reserving_fee(动态)
    vault.acc_reserving_rate(累计费率)
    reserved_fee = (2000 - 1000) * position.reserved


    持有 lp 会有利润吗，是怎么计算的 ？
    pyth 怎么喂价的 ？



1. Agdex
    a.  合约测打印日志
    b.  js 调用开仓脚步 
    c.  批量 执行调用开仓脚步

2. frontend
    run dev
    sync chensuo

3. rns
    swap & pay on evm
    subscription on evm
    swap & pay on solana 
    subscription on solana
    swap & pay on ton
    subscription on ton

4. ton & tact learning 

    

