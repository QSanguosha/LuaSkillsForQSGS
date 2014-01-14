--[[
	代码速查手册（F区）
	技能索引：
		反间、反间、反馈、放权、放逐、飞影、焚城、焚心、奋激、奋迅、愤勇、奉印、伏枥、扶乱、辅佐、父魂、父魂
]]--
--[[
	技能名：反间
	相关武将：标准·周瑜
	描述：出牌阶段限一次，若你有手牌，你可以令一名其他角色选择一种花色，然后该角色获得你的一张手牌再展示之，若此牌的花色与其所选的不同，你对其造成1点伤害。
	引用：LuaFanjian
	状态：验证通过
]]--
LuaFanjianCard = sgs.CreateSkillCard{
	name = "LuaFanjianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local dest = targets[1]
		local id = source:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(id)
		local suit = room:askForSuit(dest, self:objectName())
		room:getThread():delay()
		dest:obtainCard(card)
		room:showCard(dest, id)
		if card:getSuit() ~= suit then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = source
			damage.to = dest
			room:damage(damage)
		end
	end
}
LuaFanjian = sgs.CreateViewAsSkill{
	name = "LuaFanjian",
	n = 0,
	view_as = function(self, cards)
		local card = LuaFanjianCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#LuaFanjianCard")
		end
		return false
	end
}
--[[
	技能名：反间
	相关武将：翼·周瑜
	描述：出牌阶段，你可以选择一张手牌，令一名其他角色说出一种花色后展示并获得之，若猜错则其受到你对其造成的1点伤害。每阶段限一次。
	引用：LuaXNeoFanjian
	状态：验证通过
]]--
LuaXNeoFanjianCard = sgs.CreateSkillCard{
	name = "LuaXNeoFanjianCard",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local subid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(subid)
		local card_id = card:getEffectiveId()
		local suit = room:askForSuit(target, "LuaXNeoFanjian")
		room:getThread():delay()
		target:obtainCard(self)
		room:showCard(target, card_id)
		if card:getSuit() ~= suit then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = source
			damage.to = target
			room:damage(damage)
		end
	end
}
LuaXNeoFanjian = sgs.CreateViewAsSkill{
	name = "LuaXNeoFanjian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaXNeoFanjianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#LuaXNeoFanjianCard")
		end
		return false
	end
}
--[[
	技能名：反馈
	相关武将：标准·司马懿
	描述：每当你受到一次伤害后，你可以获得伤害来源的一张牌。
	引用：LuaFankui
	状态：验证通过
]]--
LuaFankui = sgs.CreateTriggerSkill{
	name = "LuaFankui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local source_data = sgs.QVariant()
		source_data:setValue(source)
		if source then
			if not source:isNude() then
				if room:askForSkillInvoke(player, self:objectName(), source_data) then
					local card_id = room:askForCardChosen(player, source, "he", self:objectName())
					room:obtainCard(player, card_id)
				end
			end
		end
	end
}
--[[
	技能名：放权
	相关武将：山·刘禅
	描述：你可以跳过你的出牌阶段，若如此做，你在回合结束时可以弃置一张手牌令一名其他角色进行一个额外的回合。
	引用：LuaFangquan、LuaFangquanGive
	状态：1217验证通过
]]--
LuaFangquan = sgs.CreateTriggerSkill{
	name = "LuaFangquan" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			local invoked = false
			if player:isSkipped(sgs.Player_Play) then return false end
			invoked = player:askForSkillInvoke(self:objectName())
			if invoked then
				player:setFlags("LuaFangquan")
				player:skip(sgs.Player_Play)
			end
		elseif change.to == sgs.Player_NotActive then
			if player:hasFlag("LuaFangquan") then
				if not player:canDiscard(player, "h") then return false end
				if not room:askForDiscard(player, "LuaFangquan", 1, 1, true) then return false end
				local _player = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				local p = _player
				local playerdata = sgs.QVariant()
				playerdata:setValue(p)
				room:setTag("LuaFangquanTarget", playerdata)
			end
		end
		return false
	end
}
LuaFangquanGive = sgs.CreateTriggerSkill{
	name = "#LuaFangquan-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("LuaFangquanTarget") then
			local target = room:getTag("LuaFangquanTarget"):toPlayer()
			room:removeTag("LuaFangquanTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}
--[[
	技能名：放逐
	相关武将：林·曹丕、铜雀台·曹丕
	描述：每当你受到一次伤害后，你可以令一名其他角色摸X张牌（X为你已损失的体力值），然后该角色将其武将牌翻面。
	引用：LuaFangzhu
	状态：验证通过
]]--
LuaFangzhu = sgs.CreateTriggerSkill{
	name = "LuaFangzhu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local list = room:getOtherPlayers(player)
			local target = room:askForPlayerChosen(player, list, self:objectName())
			if target then
				local count = player:getLostHp()
				room:drawCards(target, count, self:objectName())
				target:turnOver()
			end
		end
	end
}
--[[
	技能名：飞影（锁定技）
	相关武将：神·曹操、倚天·魏武帝
	描述：其他角色计算的与你的距离+1。
	引用：LuaFeiying
	状态：验证通过
]]--
LuaFeiying = sgs.CreateDistanceSkill{
	name = "LuaFeiying",
	correct_func = function(self, from, to)
		if to:hasSkill("LuaFeiying") then
			return 1
		end
	end,
}
--[[
	技能名：焚城（限定技）
	相关武将：一将成名2013·李儒
	描述：出牌阶段，你可以令所有其他角色选择一项：弃置X张牌，或受到你对其造成的1点火焰伤害。（X为该角色装备区牌的数量且至少为1）
	引用：LuaFencheng
	状态：验证通过
]]--
LuaFenchengCard = sgs.CreateSkillCard{
	name = "LuaFenchengCard",
	mute = true,
	target_fixed = true,

	on_use = function(self, room, source, targets)
		local players = room:getOtherPlayers(source)
			room:removePlayerMark(source, "@burn")
		for _,p in sgs.qlist(players) do
		if p:isAlive() then
			room:cardEffect(self,source, p)
		end
	end
end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local players = room:getOtherPlayers(effect.from)
		for _,player in sgs.qlist(players) do
		local length = player:getEquips():length()
		if length == 0 then length = 1 end
		if not player:canDiscard(effect.to,"he") or not room:askForDiscard(player,self:objectName(),length,length, true,true) then
		room:damage(sgs.DamageStruct(self:objectName(),effect.from,player, 1,sgs.DamageStruct_Fire))
		end
	end
end
}
LuaFenchengVs = sgs.CreateViewAsSkill{
	name = "LuaFencheng",
	n = 0,

	view_as = function(self, cards)
		return LuaFenchengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@burn") >= 1
	end
}
LuaFencheng = sgs.CreateTriggerSkill{
	name = "LuaFencheng" ,
	frequency = sgs.Skill_Limited ,
	events = {sgs.GameStart} ,
	view_as_skill = LuaFenchengVs ,

	on_trigger = function(self, event, player, data)
		player:gainMark("@burn",1)
	end
}
--[[
	技能名：焚心（限定技）
	相关武将：铜雀台·灵雎、SP·灵雎
	描述：当你杀死一名非主公角色时，在其翻开身份牌之前，你可以与该角色交换身份牌。（你的身份为主公时不能发动此技能。）
	引用：LuaXFenxin、LuaXFenxinStart
	状态：验证通过
]]--
LuaXFenxin = sgs.CreateTriggerSkill{
	name = "LuaXFenxin",
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mode = room:getMode()
		if string.sub(mode, -1) == "p" or string.sub(mode, -2) == "pd" or string.sub(mode, -2) == "pz" then
			local dying = data:toDying()
			if dying.damage then
				local killer = dying.damage.from
				if killer and not killer:isLord() then
					if not player:isLord() and player:getHp() <= 0 then
						if killer:hasSkill(self:objectName()) then
							if killer:getMark("@burnheart") > 0 then
								room:setPlayerFlag(player, "FenxinTarget")
								local ai_data = sgs.QVariant()
								ai_data:setValue(player)
								if room:askForSkillInvoke(killer, self:objectName(), ai_data) then
									killer:loseMark("@burnheart")
									local role1 = killer:getRole()
									local role2 = player:getRole()
									killer:setRole(role2)
									room:setPlayerProperty(killer, "role", sgs.QVariant(role2))
									player:setRole(role1)
									room:setPlayerProperty(player, "role", sgs.QVariant(role1))
								end
								room:setPlayerFlag(player, "-FenxinTarget")
								return false
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
LuaXFenxinStart = sgs.CreateTriggerSkill{
	name = "#LuaXFenxinStart",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@burnheart", 1)
	end
}
--[[
	技能名：奋激
	相关武将：风·周泰
	描述：每当一名角色的手牌因另一名角色的弃置或获得为手牌而失去后，你可以失去1点体力：若如此做，该角色摸两张牌。 
]]--
--[[
	技能名：奋迅
	相关武将：国战·丁奉
	描述：出牌阶段限一次，你可以弃置一张牌并选择一名其他角色，你获得以下锁定技：本回合你无视与该角色的距离。
	引用：LuaXFenxun
	状态：0224验证通过
]]--
LuaXFenxunCard = sgs.CreateSkillCard{
	name = "LuaXFenxunCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local tag = sgs.QVariant()
		tag:setValue(effect.to)
		effect.from:setTag("FenxunTarget", tag)
		room:setFixedDistance(effect.from, effect.to, 1)
	end
}
LuaXFenxunVS = sgs.CreateViewAsSkill{
	name = "LuaXFenxunVS",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local first = LuaXFenxunCard:clone()
			first:addSubcard(cards[1])
			first:setSkillName(self:objectName())
			return first
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaXFenxunCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}
LuaXFenxun = sgs.CreateTriggerSkill{
	name = "#LuaXFenxun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill},
	view_as_skill = LuaXFenxunVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if not victim or victim:objectName() ~= player:objectName() then
				return false
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() ~= "LuaXFenxunVS" then
				return false
			end
		end
		local tag = player:getTag("FenxunTarget")
		if tag then
			local target = tag:toPlayer()
			if target then
				room:setFixedDistance(player, target, -1)
				player:removeTag("FenxunTarget")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			local tag = target:getTag("FenxunTarget")
			if tag then
				return tag:toPlayer()
			end
		end
		return false
	end
}
--[[
	技能名：愤勇
	相关武将：☆SP·夏侯惇
	描述：每当你受到一次伤害后，你可以竖置你的体力牌；当你的体力牌为竖置状态时，防止你受到的所有伤害。
	引用：LuaFenyong、LuaFenyongClear
	状态：验证通过
]]--
LuaFenyong = sgs.CreateTriggerSkill{
	name = "LuaFenyong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:getMark("@fenyong") == 0 then
				if room:askForSkillInvoke(player, self:objectName()) then
					player:gainMark("@fenyong")
				end
			end
		elseif event == sgs.DamageInflicted then
			if player:getMark("@fenyong") > 0 then
				return true
			end
		end
		return false
	end,
}
LuaFenyongClear = sgs.CreateTriggerSkill{
	name = "#LuaFenyongClear",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		player:loseAllMarks("@fenyong")
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if not target:hasSkill("LuaFenyong") then
				return target:getMark("@fenyong") > 0
			end
		end
		return false
	end
}
--[[
	技能名：奉印
	相关武将：铜雀台·伏完
	描述：其他角色的回合开始时，若其当前的体力值不比你少，你可以交给其一张【杀】，令其跳过其出牌阶段和弃牌阶段。
	引用：LuaXFengyin
	状态：验证通过
]]--
LuaXFengyinCard = sgs.CreateSkillCard{
	name = "LuaXFengyinCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local target = room:getCurrent()
		target:obtainCard(self)
		room:setPlayerFlag(target, "fengyin_target")
	end
}
LuaXFengyinVS = sgs.CreateViewAsSkill{
	name = "LuaXFengyin",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaXFengyinCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXFengyin"
	end
}
LuaXFengyin = sgs.CreateTriggerSkill{
	name = "LuaXFengyin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart},
	view_as_skill = LuaXFengyinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local splayer = room:findPlayerBySkillName(self:objectName())
		if splayer then
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_Start then
					if player:getHp() > splayer:getHp() then
						room:askForUseCard(splayer, "@@LuaXFengyin", "@fengyin")
						return false
					end
				end
			end
			if event == sgs.EventPhaseStart then
				if player:hasFlag("fengyin_target") then
					player:skip(sgs.Player_Play)
					player:skip(sgs.Player_Discard)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：伏枥（限定技）
	相关武将：二将成名·廖化
	描述：当你处于濒死状态时，你可以将体力回复至X点（X为现存势力数），然后将你的武将牌翻面。
	引用：LuaFuli
	状态：验证通过
]]--
KingdomCount = function(targets)
	local kingdoms = {}
	for _,target in sgs.qlist(targets) do
		local flag = true
		local kingdom = target:getKingdom()
		for _,k in pairs(kingdoms) do
			if k == kingdom then
				flag = false
				break
			end
		end
		if flag then
			table.insert(kingdoms, kingdom)
		end
	end
	return kingdoms
end
LuaFuli = sgs.CreateTriggerSkill{
	name = "LuaFuli",
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local dying_data = data:toDying()
		local dest = dying_data.who
		if dest:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:loseMark("@laoji")
				local room = player:getRoom()
				local players = room:getAlivePlayers()
				local kingdoms = KingdomCount(players)
				local hp = player:getHp()
				local recover = sgs.RecoverStruct()
				recover.recover = #kingdoms - hp
				room:recover(player, recover)
				player:turnOver()
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() then
				if target:hasSkill(self:objectName()) then
					return target:getMark("@laoji") > 0
				end
			end
		end
		return false
	end
}
--[[
	技能名：扶乱
	相关武将：贴纸·王元姬
	描述：出牌阶段限一次，若你未于本阶段使用过【杀】，你可以弃置三张相同花色的牌，令你攻击范围内的一名其他角色将武将牌翻面，然后你不能使用【杀】直到回合结束。
	引用：LuaXFuluan
	状态：验证通过
]]--
LuaXFuluanCard = sgs.CreateSkillCard{
	name = "LuaXFuluanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				return sgs.Self:inMyAttackRange(to_select)
			end
		end
	end,
	on_use = function(self, room, source, targets)
		local room = source:getRoom()
		targets[1]:turnOver()
		room:setPlayerCardLimitation(source, "use", "Slash", true)
	end,
}
LuaXFuluanVS = sgs.CreateViewAsSkill{
	name = "LuaXFuluan",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected >0 then
			return to_select:getSuit() == selected[1]:getSuit()
		else
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 3 then
			local card = LuaXFuluanCard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			card:addSubcard(cards[3])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:hasUsed("#LuaXFuluanCard") or player:hasFlag("cannotDoFuluan") then
			return false
		end
		return true
	end,
}
LuaXFuluan = sgs.CreateTriggerSkill{
	name = "LuaXFuluan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	view_as_skill = LuaXFuluanVS,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local source = use.from
		if source:objectName() == player:objectName() then
			local card = use.card
			if card:isKindOf("Slash") then
				local room = player:getRoom()
				room:setPlayerFlag(player, "cannotDoFuluan")
			end
		end
	end,
}
--[[
	技能名：辅佐
	相关武将：智·张昭
	描述：当有角色拼点时，你可以打出一张点数小于8的手牌，让其中一名角色的拼点牌加上这张牌点数的二分之一（向下取整）
	引用：LuaXFuzuo
	状态：0224验证通过
]]--
LuaXFuzuo = sgs.CreateTriggerSkill{
	name = "LuaXFuzuo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PindianVerifying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local zhangzhao = room:findPlayerBySkillName(self:objectName())
		if zhangzhao then
			local pindian = data:toPindian()
			local source = pindian.from
			local target = pindian.to
			local choices = string.format("%s+%s+%s", source:getGeneralName(), target:getGeneralName(), "cancel")
			local choice = room:askForChoice(zhangzhao, self:objectName(), choices)
			if choice ~= "cancel" then
				local intervention = room:askForCard(zhangzhao, ".|.|~7|hand", "@fuzuo_card")
				local extra = intervention:getNumber()
				if intervention then
					if choice == source:getGeneralName() then
						local num = math.min((pindian.from_card:getNumber() + extra/2), 13)
						pindian.from_number = num
					else
						local num = math.min((pindian.to_card:getNumber() + extra/2), 13)
						pindian.to_number = num
					end
					data:setValue(pindian)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：父魂
	相关武将：一将成名2012·关兴&张苞
	描述：你可以将两张手牌当普通【杀】使用或打出。每当你于出牌阶段内以此法使用【杀】造成伤害后，你获得技能“武圣”、“咆哮”，直到回合结束。
]]--
--[[
	技能名：父魂
	相关武将：怀旧-一将2·关&张-旧
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出两张牌并获得之，若亮出的牌颜色不同，你获得技能“武圣”、“咆哮”，直到回合结束。
	引用：LuaFuhun
	状态：0224验证通过
]]--
LuaFuhun = sgs.CreateTriggerSkill{
	name = "LuaFuhun",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if event == sgs.EventPhaseStart and phase == sgs.Player_Draw then
			if player:askForSkillInvoke(self:objectName()) then
				local id1 = room:drawCard()
				local id2 = room:drawCard()
				local card1 = sgs.Sanguosha:getCard(id1)
				local card2 = sgs.Sanguosha:getCard(id2)
				local diff = card1:isBlack() ~= card2:isBlack()
				local move = sgs.CardsMoveStruct()
				local move2 = sgs.CardsMoveStruct()
				move.card_ids:append(id1)
				move.card_ids:append(id2)
				move.to_place = sgs.Player_PlaceTable
				room:moveCardsAtomic(move, true)
				room:getThread():delay()
				move2 = move
				move2.to_place = sgs.Player_PlaceHand
				move2.to = player
				room:moveCardsAtomic(move2, true)
				if diff then
					room:setEmotion(player, "good")
					room:acquireSkill(player, "wusheng")
					room:acquireSkill(player, "paoxiao")
					player:setFlags(self:objectName())
				else
					room:setEmotion(player, "bad")
				end
				return true
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasFlag(self:objectName()) then
				room:detachSkillFromPlayer(player, "wusheng")
				room:detachSkillFromPlayer(player, "paoxiao")
			end
		end
	end
}
