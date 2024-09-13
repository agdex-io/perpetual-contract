module perpetual::pool_test {

    use aptos_framework::coin;
    use aptos_framework::signer;
    
    use std::vector;
    use std::debug;
     use std::string::{String, utf8};
    use perpetual::pool;

    fun my_message():String {
        let msg: String = utf8(b"This is the String I want to print to the screen.");
        debug::print(&msg);
        return msg
    }
    #[test]
    fun testing(){
        let msg = my_message();
        debug::print(&msg);
    } 


    #[test(user = @0x1)]
    public fun test_compute_rebase_fee_rate(user: signer) {
        let str = utf8(b"Hello, Aptos");
        debug::print(&str);
        debug::print(&1234);
    }
}
