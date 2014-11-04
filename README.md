SpaceBase
=========

Messin' around with SpaceBase DF9. This is my first game mod and my first time using Lua. Sorry for butchering your code, DoubleFine.

Check out the latest commit changes:
https://github.com/malero/SpaceBase/commit/e0b6c5e74ee35efb315111c30a7aa3d8dc9115e0

Download the data folder:
https://github.com/malero/SpaceBase/archive/master.zip

**BALANCE CHANGES/BUG FIXES**

Some of these may seem too drastic, but I tried to balance the game for about 50 citizens that each have their own room, bed, shelves, etc. When 15 people go into a pub and deplete all of the oxygen out of it and other rooms that then makes everyone start to panic is absolutely ridiculous and annoying(I had over 2x more than enough oxygen capacity).

1. Research is a littler faster (Added quite a few new research projects)
2. Increased base repair/maintain rates (After you get a huge base with hundreds of objects you will thank me)
3. Decreased some items base decay rate(doors,emergency alarm, food replicator and other small props)
4. Decreased the amount of oxygen citizens breathe/sec (In large bases even if you had 100+ capacity, sometimes even 30 people could use enough oxygen to reduce rooms to a level where they would start to panic)
5. Reduced the oxygen threshold in which citizens panic and stop doing everything.
6. All corpses will be converted into body bags after you resume a game(sometimes they would bug out)

**NEW RESEARCH PROJECTS**

*Room Lockdown*

This is probably too overpowered and takes away a lot of the challenges in creating a good security team and turret setup. But seeing that both security teams and turrets have problems, I'm enjoying this research project quite a bit!

- Level 1: Lockdowns will deplete the oxygen in the room(I changed this, I'll have to think of something else for level 1)
- Level 2: Lockdowns will now spray a poisonous gas into the room.
- Level 3: More potent poisonous gas and chance to convert non-android enemies.
- Level 4: More potent poisonous gas and chance to convert android enemies.
- Level 5: Your base will now automatically lockdown any rooms when needed. They will unlock when there are no more enemies alive in the room.

*Portable Incinerator*

Doctors will now carry a portable incinerator to regain matter from the weak and powerless. (Helps quite a bit when you get raided by 20 or so enemies at once)

*Upgraded Technician Tools*

- Level 1: Gives the technician a 10% chance to double the repair amount.
- Level 2: Gives the technician a 20% chance to double the repair amount.
- Level 3: Gives the technician a 30% chance to double the repair amount.

*Human Resources*

You can build a terminal that will attempt to bring in new citizens. It costs 2,500 matter and is not guaranteed to work(Base 10% chance without any research).

- Level 1: Automatically assigns new citizens to an open bed. 20% chance for immigrant transmission to succeed.
- Level 2: 30% chance for immigrant transmission to succeed.
- Level 3: 40% chance for immigrant transmission to succeed.
- Level 4: 50% chance for immigrant transmission to succeed.

**NEW CONSTRUCTION ITEMS**

1. The terminal for the human resources research project
2. Killbot Controller - Allows you to make a Killbot for 5,000 matter(They can only be assign to security. Added robot themed 30+ first/last names)




