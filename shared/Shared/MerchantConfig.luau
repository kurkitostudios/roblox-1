-- Vendita bottino al mercante tribale. Tariffe PROVVISORIE.
-- Non è l'economia finale: solo materiali e collezionabili, pronti da estendere.
-- Non vende equipaggiamento, pozioni o Pet.

local MerchantConfig = {
	Rates = {
		materials = 5,
		collectibles = 18,
	},
	MaxPerSale = 100,
}

function MerchantConfig.Price(category, count)
	local rate = MerchantConfig.Rates[category]
	if not rate or type(count) ~= "number" then
		return nil
	end
	return rate * math.floor(count)
end

return MerchantConfig
