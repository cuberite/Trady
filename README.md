Trady
=====
Plugin that adds chest-based shops to MC-Server


How to install:
=====
1. Put files inside "Plugins/Trady" folder;
2. Go to your settings.ini _OR_ use web control panel, and add "Trady";
3. Make sure that you have "Handy" (v2 at least!) and "Coiny" (v6) installed;
4. Make sure that "Trady" is after "Handy" and "Coiny" on the list!;
5. ...
6. PROFIT!!!


How to setup:
=====
All settings are in "Plugins/Trady/trady_settings.ini" file. Those are following:

1. SaveMode: Timed, Paranoid, Relaxed, Dont; Timed will save every Nth tick, Paranoid will save on every change, Relaxed will save ONLY on server REGULAR shutdown, Dont won't save at all. BEWARE - trade operations won't be reverted automagically!;
2. TicksPerSave: 1200 ticks approximately are similar to one minute, so defaul 2000 is a big overkill;
3. Barter: 0/1 to toggle barter trading (could be broken ATM, so try at your own risk);
4. BarterItem: this one is definitely ATM;
5. AllowFractionalTrade: 0 = disallowed, 1 = allowed. If you don't have enough money, space in your inventory, or seller don't have enough items (let's say he sells 32 pieces of sand, but chest only has 9 left), or his cashmachine (this applies to barter trading) doesn't have enough space - operation would still be performed, within those limitations;
6. HaltSelfTrade: 0/1, when enabled, allows you to buy/sell from/to yourself. It's kinda resource loop thing, so it might cause dividing our universe by zero and kill us all. Good stuff;
7. UsingProtection: 0/1, if enabled, Trady will take care of those pesky peasants trying to steal your goods. Could be disabled for compatibility with other protection plugins, I dunno, I just coded it;
8. BreakingProtection: 0/1, same as UsingProtection, but prevents breaking chests/signs;


Creating a shop:
=====
1. Place a chest;
2. Put items you want to trade in this chest;
3. Place a sign over a chest (just like with bukkit's ChestShop);
4. Syntaxt is:
  * from_chest_price:to_chest_price
  * ammount (this is optional; over-stack ammounts, like 70, are allowed)
  * ban_fractional_trade (optional, if you want to ban fractional trading write 1 there)
  *[empty]


Using a shop:
=====
Left-click, right-click on the sign to sell/buy items.

Deleting a shop:
=====
Destroy a sign or a chest.

Permissions:
=====
1. trady.delete: allows you to delete other players' shops, for admins. But one can make a group of players "lockmasters" or some another bizzare stuff like that, so that they could go rob shops;
2. Mmmm, I don't have anything more... I probably should, don't I?