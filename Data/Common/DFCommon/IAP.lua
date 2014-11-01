local DFUtil = require("DFCommon.Util")

local m = {
    publicKey = nil,    
    productIds = {},
    receiptVerifyURL = "https://services.moaicloud.com/dfmobile/shopverify",
    productCatalog = {},
    purchasesAllowed = false,
    purchaseCallback = nil,
    failureCallback = nil,
    refundCallback = nil,    
    forceFakePurchases = false,
    
    -- Error codes for failureCallback
    kPURCHASE_DECLINED = 0,
    kPURCHASE_CANCELLED = 1,
}

-- init
-- Initialzies the lib, begins polling the system for IAP related data.
--
-- publicKey: The public key string for this app. Found in the app store mgmt web page. Currently Android only.
-- productIds: A list of product id strings that match the list in the game's app store.
-- purchaseCallback: The function to call when a purchase is successfully completed or restored.
-- failureCallback: The function called when a purchase fails. An error code will tell why the purchase failed.
-- refundCallback: The function to call when a purchase is refunded. Currently Android only.
function m.init(publicKey, productIds, receiptVerifyURL, purchaseCallback, failureCallback, refundCallback)
    m.publicKey = publicKey    
    m.productIds = productIds
    m.receiptVerifyURL = receiptVerifyURL
    m.purchaseCallback = purchaseCallback
    m.failureCallback = failureCallback
    m.refundCallback = refundCallback
    
    if MOAIEnvironment.osBrand == "iOS" then
        MOAIBilling.setListener ( MOAIBilling.PAYMENT_QUEUE_TRANSACTION, m._onPaymentQueueTransaction_iOS )
        MOAIBilling.setListener ( MOAIBilling.PRODUCT_REQUEST_RESPONSE, m._productRequestResponseCallback_iOS )        
    elseif MOAIEnvironment.osBrand == "Android" then
        MOAIBilling.setListener( MOAIBilling.CHECK_BILLING_SUPPORTED, m._purchasePermissionsCallback )
        MOAIBilling.setListener( MOAIBilling.PURCHASE_RESPONSE_RECEIVED, m._onPurchaseResponseReceived_Android )
        MOAIBilling.setListener( MOAIBilling.PURCHASE_STATE_CHANGED, m._onPurchaseStateChanged_Android )        
        MOAIBilling.setListener( MOAIBilling.RESTORE_RESPONSE_RECEIVED, m._onRestoreResponseReceived_Android )               
                
        MOAIBilling.setPublicKey(publicKey)
        -- Eventually will have to add Amazon support here
        MOAIBilling.setBillingProvider( MOAIBilling.BILLING_PROVIDER_GOOGLE )
    else
        -- fake it till you make it!
    end
           
    m._updateStore()    
end

-- arePurchasesAllowed
-- Returns true if purchases are allowed by the system, false otherwise.
-- Clients should call this function before presenting any IAP UI to the player.
--
-- On some systems it takes time to determine this so may be false right away
-- an true later on. Similarly, it can change state at any moment in the app lifecycle.
function m.arePurchasesAllowed()
    return m.purchasesAllowed
end

-- getProductCatalog
-- Returns the product catalog for all items in the store.
-- Currently, only fully fleshed out on iOS.
--
-- On some systems it takes time to determine this so may be false right away
-- an true later on. Similarly, it can change state at any moment in the app lifecycle.
function m.getProductCatalog()
    return m.productCatalog
end

-- purchaseItem
-- Request that the system initiate a purchase of an item in the store.
-- Must only be called based on direct user input.
-- If successful, calling this function will result in the purchaseCallback
-- being triggered, but it may be some time in the future.
--
-- productId: Identifier of product to be purchased.
function m.purchaseItem(productId)  
    if m.productCatalog[productId] ~= nil then
        if MOAIEnvironment.osBrand == "iOS" and not m.forceFakePurchases then
            MOAIBilling.requestPaymentForProduct(productId)
        elseif MOAIEnvironment.osBrand == "Android" and not m.forceFakePurchases then
            MOAIBilling.requestPurchase(productId)
        else
            m._fakePurchase(productId)
        end
    end
end

-- restorePurchases
-- Request that the relevant app backend resend any previous non-consumable purchases.
-- Restored purchases will appear as regular purchaseCallbacks.
--
-- Note: Only necessary on iOS presently
function m.restorePurchases()
    if MOAIEnvironment.osBrand == "iOS" then
        MOAIBilling.restoreCompletedTransactions()
    end
end

-- shutdown
-- Terminates the IAP system
function m.shutdown()
    m.storeUpdateThread = nil
    m.fakePurchaseThread = nil
end

-- Private Functions

function m._updateStore()
    m.storeUpdateThread = MOAICoroutine.new()
	m.storeUpdateThread:run(
        function()
            while true do                
                if MOAIEnvironment.osBrand == "iOS" then
                    -- some platforms have a delayed response, so mimic that on iOS
                    DFUtil.sleep(0.5)
                    m._purchasePermissionsCallback( MOAIBilling.canMakePayments() )
                elseif MOAIEnvironment.osBrand == "Andorid" then
                    -- fire off a request to see if we can make purchses on this device
                    MOAIBilling.checkBillingSupported()
                    -- wait a few seconds to see if our billing status has changed
                    -- TODO: early out when we get the callback
                    DFUtil.sleep(2)
                else                    
                    -- some platforms have a delayed response, so mimic that in the faker path.
                    DFUtil.sleep(0.5)
                    -- test platforms can always make IAP                    
                    m._purchasePermissionsCallback( true )
                end
                
                if m.purchasesAllowed then
                    if MOAIEnvironment.osBrand == "iOS" then
                        MOAIBilling.requestProductIdentifiers( m.productIds )
                    elseif MOAIEnvironment.osBrand == "Android" then
                        -- not sure what to do here, pending info from Moai
                        -- for now, just fill out a basic catalog.
                        DFUtil.sleep(0.5)
                        for i,v in ipairs(m.productIds) do
                            m.productCatalog[v] = {
                                id = v,
                            }
                        end
                    else
                        DFUtil.sleep(0.5)
                        m._createFakeCatalog()
                    end
                end
                
                -- recheck the billing status every so often as users can change it outside the app
                DFUtil.sleep(300)
            end
        end
    )
end

-- Universal Callbacks

-- _purchasePermissionsCallback
-- Called when device purchase permission state changes.
-- On many systems, this callback is async.
--
-- allowed: State of purchase system at time of callback.
function m._purchasePermissionsCallback( allowed )    
    if not m.purchasesAllowed and allowed and MOAIEnvironment.osBrand == "Android" then
        MOAIBilling.restoreTransactions()
    end
    m.purchasesAllowed = allowed
end

-- iOS Callbacks

-- _productRequestResponseCallback_iOS
-- Called when the store delivers a new list of items.
-- 
-- products: Table of purchaseable items and properties.
function m._productRequestResponseCallback_iOS( products )
    m.productCatalog = {}    
	for i, v in ipairs( products ) do
        m.productCatalog[v.productIdentifier] = {
            id = v.productIdentifier,
            title = v.localizedTitle,
            description = v.localizedDescription,
            price = v.price,
            localizedPrice = v.localizedPrice,
            priceLocale = v.priceLocale,            
        }
	end
end

-- _onPaymentQueueTransaction_iOS
-- Called when a transaction is completed (successfully or unsuccessfully)
-- Generally, we only care about successful purchases.
--
-- transaction: Table describing all relevant state for the transaction.
function m._onPaymentQueueTransaction_iOS( transaction )
    if (transaction.transactionState == MOAIBilling.TRANSACTION_STATE_PURCHASED or transaction.transactionState == MOAIBilling.TRANSACTION_STATE_RESTORED) and m.purchaseCallback then        
        if m.receiptVerifyURL then
            local recieptThread = MOAICoroutine.new()
            recieptThread:run(
                function()
                    local localReceiptTask = MOAIHttpTask.new() 
                    localReceiptTask:setTimeout( 5 )      
                    
                    local reqBuffer = MOAIDataBuffer.new()
                    reqBuffer:base64Encode(transaction.transactionReceipt)                    
                    
                    localReceiptTask:httpPost(m.receiptVerifyURL, reqBuffer:getString(), nil, nil, true)
                    local receiptResults = MOAIJsonParser.decode(localReceiptTask:getString())
                    local connectedToServer = localReceiptTask:getResponseCode() == 400 or localReceiptTask:getResponseCode() == 200
                    if connectedToServer and (receiptResults == nil or receiptResults.status ~= 0) then
                        if m.failureCallback then
                            m.failureCallback(transaction.payment.productIdentifier, m.kPURCHASE_DECLINED)
                        end
                    else
                        if m.purchaseCallback then
                            m.purchaseCallback(transaction.payment.productIdentifier, transaction.payment.quantity, transaction.transactionState == MOAIBilling.TRANSACTION_STATE_RESTORED)
                        end
                    end
                end
            )
        else
            m.purchaseCallback(transaction.payment.productIdentifier, transaction.payment.quantity, transaction.transactionState == MOAIBilling.TRANSACTION_STATE_RESTORED)
        end

        
    elseif transaction.transactionState == MOAIBilling.TRANSACTION_STATE_FAILED and m.failureCallback then
        m.failureCallback(transaction.payment.productIdentifier, m.kPURCHASE_DECLINED )
    elseif transaction.transactionState == MOAIBilling.TRANSACTION_STATE_CANCELLED and m.failureCallback then
        m.failureCallback(transaction.payment.productIdentifier, m.kPURCHASE_CANCELLED )
    end
end

-- Android Callbacks

-- _onRestoreResponseReceived_Android
-- Called when the store refreshes the list of purchased products.
-- This is not the actual pruchase callback, merely glue for processing
-- all of the pending work.
--
-- code: The status of the request
-- more: Indicates more transactions are pending
-- offset: The offset at which to request additional transactions
function m._onRestoreResponseReceived_Android( code, more, offset )
	if code == MOAIBilling.BILLING_RESULT_SUCCESS then		
		if more then
			MOAIBilling.restoreTransactions( offset )
		end
   end
end

-- _onPurchaseResponseReceived_Android
-- Called when a purchase processing request is made.
-- This is not the actual pruchase, but a status that purchase action was taken.
-- 
-- code: The status of the request response.
-- id: The id of the product in question.
function m._onPurchaseResponseReceived_Android( code, id )
	if code == MOAIBilling.BILLING_RESULT_SUCCESS then
		print( "purchase request received" )
	elseif code == MOAIBilling.BILLING_RESULT_USER_CANCELED then
		print( "user canceled purchase" )
	else
		print( "purchase failed" )
	end
end

-- _onPurchaseStateChanged_Android
-- Called when a purchase is actually made or refunded
-- 
-- code: The status of the purchase
-- id: The id of the purchase
-- order: Not sure!
-- user: User who made the purchase
-- notification: Function to call confirming that payment was processed.
-- payload: Dev data attached to the transaction, equivalent to a void*
function m._onPurchaseStateChanged_Android( code, id, order, user, notification, payload )	
	if code == MOAIBilling.BILLING_PURCHASE_STATE_ITEM_PURCHASED and m.purchaseCallback then
        m.purchaseCallback(id, 1, false)
	elseif code == MOAIBilling.BILLING_PURCHASE_STATE_ITEM_REFUNDED and m.refundCallback then
        m.refundCallback(id, 1, true)		
    elseif code == MOAIBilling.BILLING_RESULT_USER_CANCELED and m.failureCallback then
        m.failureCallback(id, m.kPURCHASE_CANCELLED)
    elseif (code == MOAIBilling.BILLING_RESULT_BILLING_UNAVAILABLE or code == MOAIBilling.BILLING_RESULT_ITEM_UNAVAILABLE or code == MOAIBilling.BILLING_RESULT_ERROR) and m.failureCallback then
        m.failureCallback(id, m.kPURCHASE_DECLINED)	
	end

	if notification ~= nil then
		MOAIBilling.confirmNotification( notification )
	end
end

-- Faker Functions (for platforms w/ out stores)

-- _createFakeCatalog
-- Takes the list of passed in product IDs and creates a fake catalog from them.
-- No data created this way should be trusted except for the structure of said data.
function m._createFakeCatalog()    
    m.productCatalog = {}
    -- create fake version of full data
    for i,v in ipairs(m.productIds) do
        m.productCatalog[v] = {
            id = v,
            title = "Test Product",
            description = "This is for testing!",
            price = 0.99,
            localizedPrice = "$0.99",
            priceLocale = "FKM",
        }
    end
end

-- _fakePurchase
-- Pretends to make a purchase w/ the same latency pattern as a real store.
--
-- productId: The product id to be purchased.
function m._fakePurchase(productId)
    if m.fakePurchaseThread == nil then
        m.fakePurchaseThread = MOAICoroutine.new()
        m.fakePurchaseThread:run(
            function()
                DFUtil.sleep(1)
                m.purchaseCallback(productId, 1, false)            
                m.fakePurchaseThread = nil
            end
        )
    end
end

return m