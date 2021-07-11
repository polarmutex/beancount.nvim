return require'telescope'.register_extension {
    exports = {
        localTransactions = require('beancount').CopyTransaction({}),
    }
}
