local LogEntries = {

--PERSONALITY_CYNICAL = "cynical",
--PERSONALITY_OPTIMISTIC = "optimistic",
--PERSONALITY_INSECURE = "insecure",
--PERSONALITY_OVERLYENTHUSIASTIC = "overly enthusiastic",
--PERSONALITY_NONE = "none",

}

LogEntries.tPunctuation = -- Use ".." for period, "??" for question mark, "!!" for exclamation point
{
    period =        { toReplace = "%.%.", characterSet = { ".", ".", ".", "...", }, },
    question =      { toReplace = "%?%?", characterSet = { "?", "?", "??", "???", "?!", "!?", "?!?!", }, },
    exclamation =   { toReplace = "%!%!", characterSet = { "!", "!", "!", "!!", "!!!", }, },
}

LogEntries.tSpawn = 
{
    "First day on a new base.. Hopes are not high..",
    "Someone tell me why this assignment is going to be any better than the last one?",
    "What are we even supposed to be doing out here??",
    "I'm pretty excited for my new assignment!!",
    "The first day on a new base is the best.. So many people to meet!!",
    "Something tells me this crew is going to be something special..",
    "I don't think people liked me on my last base assignment.. Fingers crossed this time..",
    "Anyone have any tips on how to make a good first impression on a new base??",
    "Is it weird to try and introduce yourself to other new crewmembers?",
    "New base assignments are THE BEST!! This is going to rule!!",
    "YOU GUYS!! Welcome to the NEW BASE!! :D",
    "I don't know how this new assignment could top the old one, but I BET IT WILL!!",
}

LogEntries.tWorkout = 
{
    "Feels good to get a workout in!",
    "I am getting super close to seeing my abs. I love a good workout.",
}

LogEntries.tSocialLog =
{
    "I'm so over everything..",
    "I wasn't really into the Lars von Trier XXII remake of Mrs. Doubtfire..",
    "Maybe this time I won't get burned by putting my hand in the boiling water :D!!!!",
    "I think this jumpsuit makes me look fat..",
    "OMG!! Have you guys seen what SPACE looks like today?? It's amazing!!",
    "I LOVE SPACE!! :D :D",
}

LogEntries.tDisease =
{
    "Oh great, I have /disease/.. Does this even have a cure??",
    "So now I have /disease/.. I'll probably die.",
    "I've been reading about treatments for /disease/. Convenient, since I have it now!!",
    "I'm sure my doctor will help me recover from /disease/ in no time!!",
    "There's a cure for /disease/.. Right??",
    "Oh no, I've contracted /disease/.. :(",
    "WHAT!!!! I just got /disease/!!! HOW???",
    "Anybody else contracted /disease/ up in here?? LOL!! XD",
}

LogEntries.tNewJob =
{
    "So, I was /jobverb/ to /newjob/.. Whoopdee doo..",
    "They say being a /newjob/ is the worst job around.. Lucky me..",
    "I just got /jobverb/ to /newjob/!! Exciting!!",
    "I'm really going to throw myself into my new job as a /newjob/!!",
    "I've never been a /newjob/ before.. Dunno if I can hack it..",
    "Anyone have any tips at being a /newjob/??",
    "YES!! I was /jobverb/ to /newjob/!!!! ~~nEw oPpOrTuNiTiEs~~~",
    "Guess who just got /jobverb/ to /newjob/!!!! XD",
}

LogEntries.tLostJob =
{
    "So, I got canned today.. Real nice..",
    "Fired?? You kidding me??",
    "Not thrilled about being let go, but it's a chance for new opportunities!!",
    "Lost my job today.. Keeping my eyes on tomorrow!! :)",
    "Oh god, I lost my job.. What am I going to do??",
    "Anyone have any tips for the recently out of work??",
    "Welp, NO MORE JOB!! More time FOR ME!! XD",
    "I plan to take FULL ADVANTAGE of my new funemployed status!! :D",
}

LogEntries.tIdle = 
{
    "These pants are much more comfortable than they look..",
    "I may have ordered too many business cards..",
    "Am I too obsessive about tracking calories?? How many calories are in Space Chapstick?",
    "I'm the one who started the petition..",
    "Finally listening to the new Rat Chaos. Opinions divided, but better than the first album.",
    "Where does S.O.A.P. come from??",
    "Had the dream about the spiders again..",
    "My mom emailed me.. Emailed! How quaint..",
    "I try to impress crewmates by saying my hand's cybernetic. It's just a normal hand though.",
    "There's a petition going around to change this base's cat policy..",
    "I miss Earth coffee..",
    "I honestly didn't mean to use up all the hot water..",
    "I seem to have misplaced my hot sauce.. Again..",
    "Don't tell a crewmate they resemble your ex. Even if they do. Trust me..",
    "This is my last clean pair of pants..",
    "I'm still not really sure what I'm doing here..",
    "I think someone threw out my scrap of paper with all my pass codes..",
    "I've narrowed down the list of suspects who may be responsible for the bathroom incident..",
    "The opposite of reverse psychology is psychology, right? I mainly get what I want that way.",
    "People say they like my new look, so I'm not saying it was the result of a lab accident.",
    "I think the snow cone maker is offline because parts of it were used to fix the reactor..",
}

LogEntries.tWorkGood = 
{
    "So, we have no concept of currency, but I still got a boss.. Explain that..",
    "If anyone ever tells you the /job/ life is glamorous, don't believe 'em.",
    "My advice for those trying to become a /job/? Don't..",
    "Things are really looking up at work!!",
    "I hear profits are up at work this quarter!! Well, they would be if we used money..",
    "I'm so glad to be a /job/!!",
    "I think I did good work today. Maybe not, though.. I should ask a coworker..",
    "I'm really only on /job/ duty because it was assigned to me..",
    "How do know if you're doing okay at work? They never give us evaluations..",
    "I love my job! I'm all about improving the quality of life of my cohabitants!!",
    "My coworkers are the best!! Going to work is the highlight of my day..",
    "It is AMAZING to get to work /job/ duty!! I'm so lucky!! :D :D",
}

LogEntries.tWorkBad = 
{
    "My job sucks.",
    "What's the point hiring a /job/ and then having no place to do the job??",
    "I take a job as a /job/, but now I got nowhere to go. Nice.",
    "I can't wait until they actually set up my workplace!!",
    "They'll probably have somewhere for me to work by tomorrow..",
    "I wonder if any other /job/s have a place to go..",
    "Can we ask someone where the /job/ workplace is?",
    "I HAVE NOWHERE TO GO FOR WORK!! LOL XD",
    "I guess there's no office for /job/s?? :O",
}

LogEntries.tUnemployed =
{
    "Another day with no job.. Another day closer to the grave.. Well, the airlock, anyway..",
    "Look at all those dumb saps wasting their days away at work.. A bunch of sheep..",
    "What exactly are you supposed to do in the middle of space without a job??",
    "Still no job, but I have a good feeling about tomorrow!!",
    "I'm sure the employment database will find me a good match any moment now!!",
    "Even with no official employment, there are always ways to pass the time!! ;)",
    "Still job-hunting. My resume is probably too boring.. Or maybe it's just me..",
    "If I asked someone for a job, would that make me seem aggressive?",
    "Without a job, I'm really starting to doubt my self worth..",        
    "Who cares if I have no job?? More time for ME!! :D",
    "Shout out to my funemployed space homies!! :D",
    "Who wants to ditch work with me?? Not that I actually have a job.. LOL!! XD",
}

LogEntries.tSleepOnFloor = 
{
    "I'm pretty sure they're putting something in the water to make us drowsy.",
    "I can never decide if it's a relief or a disappointment not to wake up dead.",
    "Waking up on the floor pretty much guarantees that it'll be garbage day.",
    "This is going to be a good day..",
    "This base is just a good place to catch some shut-eye, if you ask me!!",    
    "I wonder if the bags under my eyes are noticeable..",
    "Waking up on a space station is THE BEST!!",
    "I'm sick of sleeping on the floor like an animal.",
    "I was so tired last night, I just zonked out on the floor! LOL",
    "Time might be totally arbitrary on a space station, but I still love getting up in the morning!!",
    "Well, I have nowhere to sleep. And this is supposed to be the future..",
    "Rough night! Fingers crossed to find a sleeping pod tomorrow!!",
    "How do you admit to your friends you have nowhere to sleep at night?",
    "A sleeping pod would be nice, but sometimes ya gotta ROUGH IT!! XD",
}

LogEntries.tSleepInBed = 
{
    "Well, last night I threw away a third of my day lying in a pod. Remind me why we need sleep again??",
    "Are my living quarters where the cool people live??",
    "Space-poke me if you're feeling rested!!",
    "So tired.. I wonder if my quarters aren't getting enough oxygen??",
    "I think someone put a pea under my sleep pod..",
	"I'm pretty sure they're putting something in the water to make us drowsy.",
    "I can never decide if it's a relief or a disappointment not to wake up dead.",
    "This is going to be a good day..",
    "A good night of sleep is the first step to a good day..",
    "This base is just a good place to catch some shut-eye, if you ask me!!",
    "Waking up on a space station is THE BEST!!",
    "Time might be totally arbitrary on a space station, but I still love getting up in the morning!!",
    "I LOVE waking up on this base!!",
}

LogEntries.tRelaxGood = 
{
    "Wandered around the base today. I guess this is what idiots do to pass the time..",
    "It's always good to take some time for yourself!!",
    "I got some pure relaxation in today.. I should unwind more often..",
    "LUV 2 CHILLAX IN SPACE!! XD",
}

LogEntries.tRelaxBad =
{
    "How are you supposed to relax when you're stranded in the middle of space??",
    "Just couldn't find my rhythm today. Tomorrow: relaxation central!!",
    "Sometimes I worry that I'm not really relaxing properly.. Is that a thing??",
    "Ever have one of those days where you just can't relax???? XD",
}

LogEntries.tEatGood = 
{
    "Today's reconstituted edible nutrient ration wasn't quite as vile as usual..",
    "Another bland edible 'meal.' What have we come to??",
    "These new, 'high energy plankton' bars are alright.. ",     
    "I think the grub around here is getting better!!",
    "A good meal leaves you better able to face the day!!",
    "Grilled Centauri Honeybat for lunch.. OMZ, so delish!!",
    "Those guys in Hydroponics really know how to grow a good space carrot",
    "Does space life provide us with all necessary vitamins? Do other people worry about this??",
    "I wonder if I'm chewing my food enough..",
    "It's not real spinach, so maybe it doesn't count that I had it stuck in my teeth all day..",
    "The food today was AWESOME!!",
    "Great reconstituted edible nutrient ration today! My compliments to the chef!!",
    "I never thought recycled food could taste so good!!",
}

LogEntries.tEatBad =
{
    "What exactly do you have to do to find some grub around here??",
    "So, I guess they've just stopped feeding us entirely at this point..",
    "I know I've complained about the food before, but at least it existed..",
    "Would I seem too irritating if I spoke up about the lack of food?",
    "I'm sure they're building some new pubs right now!!",
    "I'm pretty hungry, but I bet the new food facilities will be great!!",
    "Hunger makes me go cRaZy!!! XD Still need food tho..",
    "HOLLA IF YA SUPA HUNGRY!! :O",
    "I NEED SPACE FOOD!! X(",
}

LogEntries.tFirstMeeting = 
{
    "I've just met /other/ for the first time!",
    "Talked with /other/ today. Seems like a /praise/!",
    "First time meeting /other/ today..",
}

LogEntries.tGoodInteraction = 
{
    "I am really seeing eye to eye with /other/!!",
    "/other/ is a real /praise/!!",
    "That /other/. What a /praise/!!",
}

LogEntries.tBadInteraction = 
{
    "/other/ is kind of a /insult/..",
    "Man, /other/ sure is a /insult/..",
    "Ever notice how /other/ is pretty much a /insult/??",
}

LogEntries.tInsults = 
{
    "maroon",
    "dumb idiot",
    "space idiot",
    "goofball",
    "wacko",
    "wingnut",
    "potential serial killer",
    "discredit to the space station",
    "lunatic",
    "bore",
    "dullard",
    "lame-o",
    "goof",
}

LogEntries.tPraises =
{
    "champ",
    "space champ",
    "winner",
    "space winner",
    "solid citizen",
    "credit to the space station",
    "good egg",
    "star",
    "charmer",
}

LogEntries.tLowMorale = -- NOT YET IN USE
{
    "I'm so exhausted and sad..",
}

LogEntries.tMediumMorale =
{
    "I'm a litle stressed out, but things could be worse..",
    "Sometimes I think I'm making things unnecessarily complicated..",
}

LogEntries.tHighMorale = 
{
    "I'm in excellent spirits!!",
}

LogEntries.tFireResponse = -- NOT YET IN USE
{
    {
        "Ugh, I'm so over fires..",
        "Well, I have third degree burns, but my nurse is HOT!!",
        "I wonder if I look better if I stand closer to the flames..",
        "OMG you guys there is a FIRE on this station I AM STOKED!!",
    },
}

return LogEntries