-- Vendita disattivata finché non esiste un catalogo approvato.
-- TradingEnabled deve restare false. Le tariffe non vengono applicate.

local MerchantConfig = {
	TradingEnabled = false,
	Rates = {},
	MaxPerSale = 0,
}

function MerchantConfig.Price(category, count)
	local rate = MerchantConfig.Rates[category]
	if not rate or type(count) ~= "number" then
		return nil
	end
	return rate * math.floor(count)
end

return MerchantConfig
