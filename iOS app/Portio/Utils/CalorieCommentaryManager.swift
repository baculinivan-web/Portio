import Foundation

struct CalorieCommentary: Equatable {
    let title: String
    let message: String
}

enum CalorieCommentaryManager {
    static func commentary(
        calories: Double,
        goal: Double,
        level: UserSettings.CalorieCommentaryLevel,
        refreshSeed: Int = 0
    ) -> CalorieCommentary? {
        guard goal > 0 else { return nil }

        let progress = calories / goal
        if containsSixSeven(calories: calories, progress: progress) {
            let options = sixSevenLines(level: level)
            let index = stableIndex(calories: calories, goal: goal, refreshSeed: refreshSeed, count: options.count)
            return options[index]
        }

        let bucket = bucket(for: progress)
        let options = lines(for: bucket, level: level)
        let index = stableIndex(calories: calories, goal: goal, refreshSeed: refreshSeed, count: options.count)
        return options[index]
    }

    private enum Bucket {
        case empty
        case light
        case building
        case steady
        case close
        case over
        case wayOver
    }

    private static func containsSixSeven(calories: Double, progress: Double) -> Bool {
        let roundedCalories = String(Int(abs(calories.rounded())))
        let roundedPercent = String(Int(abs((progress * 100).rounded())))
        return roundedCalories.contains("67") || roundedPercent.contains("67")
    }

    private static func bucket(for progress: Double) -> Bucket {
        switch progress {
        case _ where progress <= 0:
            return .empty
        case ..<0.25:
            return .light
        case ..<0.50:
            return .building
        case ..<0.80:
            return .steady
        case ..<1.00:
            return .close
        case ..<1.15:
            return .over
        default:
            return .wayOver
        }
    }

    private static func stableIndex(calories: Double, goal: Double, refreshSeed: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let seed = Int(calories.rounded()) + Int(goal.rounded() * 0.13) + refreshSeed
        return abs(seed) % count
    }

    private static func lines(
        for bucket: Bucket,
        level: UserSettings.CalorieCommentaryLevel
    ) -> [CalorieCommentary] {
        switch level {
        case .professional:
            return professionalLines(for: bucket)
        case .sassy:
            return sassyLines(for: bucket)
        case .crazy:
            return crazyLines(for: bucket)
        }
    }

    private static func sixSevenLines(level: UserSettings.CalorieCommentaryLevel) -> [CalorieCommentary] {
        switch level {
        case .professional:
            return [
                CalorieCommentary(title: "Specific milestone", message: "Your calorie number hit 67 territory. Logging remains on track."),
                CalorieCommentary(title: "Noted: 67", message: "A distinctive number showed up. Keep using the trend, not one entry, to judge the day.")
            ]
        case .sassy:
            return [
                CalorieCommentary(title: "Six seven", message: "Six seven detected. The diary is trying very hard to be culturally relevant."),
                CalorieCommentary(title: "Number moment", message: "That 67 did not sneak past us. The calorie budget has entered meme court."),
                CalorieCommentary(title: "Six-seven incident", message: "The number said six seven and now the app needs one quiet minute.")
            ]
        case .crazy:
            return [
                CalorieCommentary(title: "SIX SEVEN", message: "Six seven on the board. The app briefly stopped tracking food and started doing middle-school crowd control."),
                CalorieCommentary(title: "67 breach", message: "Six seven detected. Your calorie log just dabbed, missed, and called it cardio."),
                CalorieCommentary(title: "Meme contamination", message: "A 67 appeared. This is no longer nutrition; this is a lunch receipt with brainrot."),
                CalorieCommentary(title: "Six-seven tribunal", message: "Six seven. The council reviewed your meal and sentenced your decision-making to supervised scrolling."),
                CalorieCommentary(title: "Certified brainrot", message: "You hit six seven. Congratulations, your diary now has the nutritional maturity of a cafeteria chant."),
                CalorieCommentary(title: "Six seven autopsy", message: "Six seven showed up and somehow made this meal look like it was planned by a group chat.")
            ]
        }
    }

    private static func professionalLines(for bucket: Bucket) -> [CalorieCommentary] {
        switch bucket {
        case .empty:
            return [
                CalorieCommentary(title: "No intake logged", message: "Nothing is recorded yet. Add a meal when you are ready."),
                CalorieCommentary(title: "Empty day", message: "No calories logged so far. Your totals will update after the first entry."),
                CalorieCommentary(title: "Ready to start", message: "The day is clear. Logging the first meal will make the trend useful."),
                CalorieCommentary(title: "No data yet", message: "Calories are at zero, so there is nothing to evaluate yet.")
            ]
        case .light:
            return [
                CalorieCommentary(title: "Gentle start", message: "Plenty of room left for a balanced meal later."),
                CalorieCommentary(title: "Early intake", message: "Calories are still low for the day, so keep energy in mind."),
                CalorieCommentary(title: "Low intake", message: "You are well under target. A planned meal can help avoid rushing later."),
                CalorieCommentary(title: "Open budget", message: "Most of the calorie goal is still available.")
            ]
        case .building:
            return [
                CalorieCommentary(title: "Good pacing", message: "You are building toward the goal without crowding it yet."),
                CalorieCommentary(title: "On track", message: "A steady pace today. Protein and fiber can help the rest land well."),
                CalorieCommentary(title: "Measured progress", message: "The day is moving, with enough flexibility left for later meals."),
                CalorieCommentary(title: "Room to plan", message: "There is still space in the budget for a balanced next choice.")
            ]
        case .steady:
            return [
                CalorieCommentary(title: "Steady progress", message: "You are past the midpoint, so the next meal can be intentional."),
                CalorieCommentary(title: "Balanced window", message: "There is still room to adjust the day with smart portions."),
                CalorieCommentary(title: "Midday check", message: "This is a good point to review protein, carbs, and fat together."),
                CalorieCommentary(title: "Useful pace", message: "Calories are in a normal working range for the day.")
            ]
        case .close:
            return [
                CalorieCommentary(title: "Close to target", message: "You are nearing the calorie goal. Smaller additions may fit best."),
                CalorieCommentary(title: "Approaching goal", message: "A lighter choice can help keep the day aligned."),
                CalorieCommentary(title: "Limited room", message: "The remaining budget is narrow, so portions matter more now."),
                CalorieCommentary(title: "Final stretch", message: "You are close enough that small snacks can change the outcome.")
            ]
        case .over:
            return [
                CalorieCommentary(title: "Goal reached", message: "You are slightly over target. Consider a lighter finish today."),
                CalorieCommentary(title: "Past target", message: "Calories are above goal, so focus on balance rather than adding more."),
                CalorieCommentary(title: "Slight overshoot", message: "The goal has been exceeded, but the day can still finish calmly."),
                CalorieCommentary(title: "Above plan", message: "You are over target. Prioritize simple, nutrient-dense choices from here.")
            ]
        case .wayOver:
            return [
                CalorieCommentary(title: "High intake", message: "Today is well above target. Let the next choices be simple and steady."),
                CalorieCommentary(title: "Over target", message: "No panic needed, but the calorie budget is clearly spent for today."),
                CalorieCommentary(title: "Large overshoot", message: "The day is far beyond target. Use the log as feedback for tomorrow."),
                CalorieCommentary(title: "Budget exceeded", message: "Additional intake will widen the gap, so a pause may help.")
            ]
        }
    }

    private static func sassyLines(for bucket: Bucket) -> [CalorieCommentary] {
        switch bucket {
        case .empty:
            return sassyZeroLines()
        case .light, .building:
            return sassyLowLines()
        case .steady:
            return sassyMediumLines()
        case .close:
            return sassyAlmostLines()
        case .over:
            return sassyOvershootLines()
        case .wayOver:
            return sassyMassiveOvershootLines()
        }
    }

    private static func sassyZeroLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Zero calories logged", message: "My psychic powers are off today. You're going to have to actually type what you ate."),
            CalorieCommentary(title: "Zero calories logged", message: "I know you didn't just photosynthesize all day. Start logging, darling."),
            CalorieCommentary(title: "Zero calories logged", message: "A blank diary? You're either fasting or in deep denial."),
            CalorieCommentary(title: "Zero calories logged", message: "I can't track invisible food. Tap the button and confess."),
            CalorieCommentary(title: "Zero calories logged", message: "Not logging it doesn't mean the calories don't count. Nice try, though."),
            CalorieCommentary(title: "Zero calories logged", message: "Are we pretending you haven't eaten yet? Because my battery is dying waiting for you."),
            CalorieCommentary(title: "Zero calories logged", message: "Your food log is as empty as my patience. Let's get moving."),
            CalorieCommentary(title: "Zero calories logged", message: "Unless you're running purely on drama today, log your breakfast."),
            CalorieCommentary(title: "Zero calories logged", message: "I see we're playing hard to get with the food diary. Put the numbers in."),
            CalorieCommentary(title: "Zero calories logged", message: "Still zero? Don't make me guess, because I will assume you ate an entire cake.")
        ]
    }

    private static func sassyLowLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Low calories", message: "Half a grape is not a personality trait. Eat something substantial."),
            CalorieCommentary(title: "Low calories", message: "Are you saving your appetite for a banquet? Log the rest."),
            CalorieCommentary(title: "Low calories", message: "A few crumbs won't power you through the day. Fuel up, buttercup."),
            CalorieCommentary(title: "Low calories", message: "You've eaten less than a pigeon in a park. Go find some actual food."),
            CalorieCommentary(title: "Low calories", message: "This is giving \"I forgot my lunch\" energy. Please go eat."),
            CalorieCommentary(title: "Low calories", message: "Don't be shy, put some more food in the log. We both know you're hungry."),
            CalorieCommentary(title: "Low calories", message: "You can't run on just iced coffee and vibes. Have a snack."),
            CalorieCommentary(title: "Low calories", message: "Is this a diet or a boycott? Eat something before you get cranky."),
            CalorieCommentary(title: "Low calories", message: "Oh, so we are just casually snacking today? Cute, but I need real meals."),
            CalorieCommentary(title: "Low calories", message: "Your protein goal is laughing at you right now. Go eat.")
        ]
    }

    private static func sassyMediumLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Medium calories", message: "Halfway there. You're giving solid \"C average\" energy right now."),
            CalorieCommentary(title: "Medium calories", message: "Right in the middle. Try not to mess up the second half of your day."),
            CalorieCommentary(title: "Medium calories", message: "You're at 50%. Let's see if your self-control lasts until dinner."),
            CalorieCommentary(title: "Medium calories", message: "Perfectly balanced. Now don't ruin it by ordering a massive burger later."),
            CalorieCommentary(title: "Medium calories", message: "Half done. Keep this up and I might actually be impressed today."),
            CalorieCommentary(title: "Medium calories", message: "You're coasting right down the middle. Don't fall asleep at the wheel."),
            CalorieCommentary(title: "Medium calories", message: "50% down. The next 50% is where the real drama happens, isn't it?"),
            CalorieCommentary(title: "Medium calories", message: "Looking good so far. Just step away from the food delivery apps."),
            CalorieCommentary(title: "Medium calories", message: "Not too much, not too little. Very Goldilocks of you."),
            CalorieCommentary(title: "Medium calories", message: "You're halfway to the finish line. Don't trip over a snack now.")
        ]
    }

    private static func sassyAlmostLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Almost at the goal", message: "You are literally one chicken nugget away from the limit. Proceed with caution."),
            CalorieCommentary(title: "Almost at the goal", message: "Danger zone. Breathing near a bakery will put you over the edge right now."),
            CalorieCommentary(title: "Almost at the goal", message: "We are at capacity. Put the fork down and slowly back away."),
            CalorieCommentary(title: "Almost at the goal", message: "Look at you, living on the edge. Time to switch to tap water."),
            CalorieCommentary(title: "Almost at the goal", message: "One more bite and this beautiful green bar turns angry red. Your choice."),
            CalorieCommentary(title: "Almost at the goal", message: "You've reached the \"chewing gum for dessert\" phase of the day."),
            CalorieCommentary(title: "Almost at the goal", message: "Almost there! Go brush your teeth so you aren't tempted to snack."),
            CalorieCommentary(title: "Almost at the goal", message: "You're walking a tightrope. Don't let a stray carb push you off."),
            CalorieCommentary(title: "Almost at the goal", message: "Close the fridge. I repeat, step away and close the fridge."),
            CalorieCommentary(title: "Almost at the goal", message: "You have just enough room left for a single deep breath. Enjoy it.")
        ]
    }

    private static func sassyOvershootLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Overshoot", message: "So much for boundaries. I guess the limit was just a light suggestion."),
            CalorieCommentary(title: "Overshoot", message: "You just had to have the last bite, didn't you? Classic."),
            CalorieCommentary(title: "Overshoot", message: "Well, the budget is broken. Hope that extra snack was worth my judgment."),
            CalorieCommentary(title: "Overshoot", message: "A little over the top today. Your fitness watch is definitely sighing."),
            CalorieCommentary(title: "Overshoot", message: "We grazed past the finish line. Tomorrow we try this revolutionary thing called \"stopping.\""),
            CalorieCommentary(title: "Overshoot", message: "You slipped on a banana peel right at the end. Better luck tomorrow."),
            CalorieCommentary(title: "Overshoot", message: "The limit was right there, and you just casually strolled past it."),
            CalorieCommentary(title: "Overshoot", message: "I see your willpower decided to clock out early today."),
            CalorieCommentary(title: "Overshoot", message: "Just a little over. We'll pretend it's a strategic bulk."),
            CalorieCommentary(title: "Overshoot", message: "Oops. Guess we're doing some extra walking to the metro tomorrow.")
        ]
    }

    private static func sassyMassiveOvershootLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Massive overshoot", message: "Did you accidentally order the entire menu? Because the math isn't mathing."),
            CalorieCommentary(title: "Massive overshoot", message: "You didn't just break the budget, you filed for calorie bankruptcy."),
            CalorieCommentary(title: "Massive overshoot", message: "Are you preparing for a long winter? Because this is a hibernation-level feast."),
            CalorieCommentary(title: "Massive overshoot", message: "Your macro chart is screaming. I'm honestly just impressed at this point."),
            CalorieCommentary(title: "Massive overshoot", message: "The calorie limit is a dot to you right now. You are in orbit."),
            CalorieCommentary(title: "Massive overshoot", message: "Did someone dare you to eat everything in sight? If so, you won."),
            CalorieCommentary(title: "Massive overshoot", message: "You treated your calorie goal like a speed bump. What a spectacular disaster."),
            CalorieCommentary(title: "Massive overshoot", message: "I'm not mad, just disappointed. And a little amazed by your stomach capacity."),
            CalorieCommentary(title: "Massive overshoot", message: "That's a lot of damage. I hope you enjoyed whatever glorious fast food caused this."),
            CalorieCommentary(title: "Massive overshoot", message: "The budget is in ashes. May your metabolism have mercy on your soul.")
        ]
    }

    private static func crazyLines(for bucket: Bucket) -> [CalorieCommentary] {
        switch bucket {
        case .empty:
            return crazyZeroLines()
        case .light, .building:
            return crazyLowLines()
        case .steady:
            return crazyMediumLines()
        case .close:
            return crazyAlmostLines()
        case .over:
            return crazyOvershootLines()
        case .wayOver:
            return crazyMassiveOvershootLines()
        }
    }

    private static func crazyZeroLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Zero calories logged", message: "Still surviving on hopes and dreams? Log your breakfast before I assume you ate the neighbor's cat."),
            CalorieCommentary(title: "Zero calories logged", message: "Photosynthesis is for plants. Unless you suddenly grew leaves, start typing."),
            CalorieCommentary(title: "Zero calories logged", message: "Blank diary. Either you're fasting like a monk, or you're too scared to admit what you actually ate."),
            CalorieCommentary(title: "Zero calories logged", message: "Did you absorb your nutrients through osmosis today? Type it in, coward."),
            CalorieCommentary(title: "Zero calories logged", message: "Zero calories logged. I'm guessing you're either asleep or a terrible liar."),
            CalorieCommentary(title: "Zero calories logged", message: "Wow, absolute zero. You're either a superhero or you forgot this app exists."),
            CalorieCommentary(title: "Zero calories logged", message: "Waiting for the food to digest before you confess? I have all day."),
            CalorieCommentary(title: "Zero calories logged", message: "Your food diary is as empty as your excuses. Log it!"),
            CalorieCommentary(title: "Zero calories logged", message: "I see we are playing \"hide and seek\" with your meals today. I'm winning."),
            CalorieCommentary(title: "Zero calories logged", message: "Air has zero calories, but I know you didn't just eat air. Spill the beans.")
        ]
    }

    private static func crazyLowLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Low calories", message: "Wow, an entire celery stick? Settle down there, competitive eater."),
            CalorieCommentary(title: "Low calories", message: "You've eaten less than a toddler at a vegetable tasting. Go get a real meal."),
            CalorieCommentary(title: "Low calories", message: "Half a calorie doesn't count as lunch. Eat something before the wind blows you away."),
            CalorieCommentary(title: "Low calories", message: "Is your diet plan just smelling bakeries as you walk by? Eat up, drama queen!"),
            CalorieCommentary(title: "Low calories", message: "My grandma's parakeet eats more than you. Go find some carbs."),
            CalorieCommentary(title: "Low calories", message: "Starving yourself won't make you taller. Get a sandwich, tiny human."),
            CalorieCommentary(title: "Low calories", message: "You're running on fumes and a single Tic-Tac. Time to refuel."),
            CalorieCommentary(title: "Low calories", message: "Congratulations, you've consumed enough energy to blink twice. Keep going."),
            CalorieCommentary(title: "Low calories", message: "A crumb is not a meal. Stop playing around and eat actual food."),
            CalorieCommentary(title: "Low calories", message: "You're eating like you owe the grocery store money. Feast a little!")
        ]
    }

    private static func crazyMediumLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Medium calories", message: "Halfway to the goal! Perfectly balanced, just like your average life choices."),
            CalorieCommentary(title: "Medium calories", message: "You're at 50%. Let's see if you can finish this without a tragic plot twist."),
            CalorieCommentary(title: "Medium calories", message: "Mid-day check-in: You're doing okay. Don't let it go to your head."),
            CalorieCommentary(title: "Medium calories", message: "You've hit the halfway mark. Now comes the hard part: not ruining it."),
            CalorieCommentary(title: "Medium calories", message: "Right in the middle. So delightfully mediocre of you. Keep it up!"),
            CalorieCommentary(title: "Medium calories", message: "50% done. I'd clap, but I'm saving my energy to judge your dinner."),
            CalorieCommentary(title: "Medium calories", message: "You're halfway there. Try not to trip over a pizza on your way to the finish line."),
            CalorieCommentary(title: "Medium calories", message: "Not starving, not stuffing your face. Who are you and what did you do to my user?"),
            CalorieCommentary(title: "Medium calories", message: "You've reached the lukewarm middle. Finish strong or fail hilariously."),
            CalorieCommentary(title: "Medium calories", message: "Solid C+ effort so far. Let's see if you can graduate today's diet.")
        ]
    }

    private static func crazyAlmostLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Almost at the goal", message: "You have exactly room for one grape. Don't you dare look at that cake."),
            CalorieCommentary(title: "Almost at the goal", message: "Walk away from the pantry. I repeat, walk away from the pantry."),
            CalorieCommentary(title: "Almost at the goal", message: "You're riding the edge. Tape your mouth shut until tomorrow morning."),
            CalorieCommentary(title: "Almost at the goal", message: "One wrong bite and you ruin the whole day. No pressure!"),
            CalorieCommentary(title: "Almost at the goal", message: "You are dangerously close to the limit. Time to chew gum and go to sleep."),
            CalorieCommentary(title: "Almost at the goal", message: "Look at you, almost succeeding! Put the cookie down and nobody gets hurt."),
            CalorieCommentary(title: "Almost at the goal", message: "You're on thin ice. A deep breath near a bakery might put you over the edge."),
            CalorieCommentary(title: "Almost at the goal", message: "Almost there. Brush your teeth now so food tastes terrible. You're welcome."),
            CalorieCommentary(title: "Almost at the goal", message: "The limit is approaching. Shut the fridge and back away slowly."),
            CalorieCommentary(title: "Almost at the goal", message: "You have 10 calories left. Enjoy licking a single almond for dinner.")
        ]
    }

    private static func crazyOvershootLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Overshoot", message: "Oops. Your self-control slipped on a banana peel, didn't it?"),
            CalorieCommentary(title: "Overshoot", message: "You just had to have that extra bite, huh? I hope it was worth the regret."),
            CalorieCommentary(title: "Overshoot", message: "You broke the budget. Tomorrow's workout is going to be fueled by pure guilt."),
            CalorieCommentary(title: "Overshoot", message: "Well, you tried. And by \"tried,\" I mean you failed, but nicely."),
            CalorieCommentary(title: "Overshoot", message: "You went slightly over. We'll just call it an accidental \"surprise bulk\" phase."),
            CalorieCommentary(title: "Overshoot", message: "So much for limits. I guess rules are just suggestions to you."),
            CalorieCommentary(title: "Overshoot", message: "The calorie goal was a line in the sand, and you just danced right over it."),
            CalorieCommentary(title: "Overshoot", message: "Just a little over. Your willpower must have taken a coffee break."),
            CalorieCommentary(title: "Overshoot", message: "You grazed past the goal line. Good job, you rebel."),
            CalorieCommentary(title: "Overshoot", message: "A little extra padding for the winter? It's okay, I'm silently judging you anyway.")
        ]
    }

    private static func crazyMassiveOvershootLines() -> [CalorieCommentary] {
        [
            CalorieCommentary(title: "Massive overshoot", message: "Did you swallow a bakery? Your calorie limit is officially crying in a corner."),
            CalorieCommentary(title: "Massive overshoot", message: "You didn't just cross the line, you took a f***ing rocket ship past it."),
            CalorieCommentary(title: "Massive overshoot", message: "Raccoons in a dumpster have better portion control than you do right now."),
            CalorieCommentary(title: "Massive overshoot", message: "Your macro chart looks like a crime scene. Are you proud of this?"),
            CalorieCommentary(title: "Massive overshoot", message: "You turned your calorie budget into confetti and ate that too."),
            CalorieCommentary(title: "Massive overshoot", message: "Did you accidentally eat a whole wedding cake? Explain yourself."),
            CalorieCommentary(title: "Massive overshoot", message: "The budget is dead. You killed it. I hope that feast was legendary."),
            CalorieCommentary(title: "Massive overshoot", message: "I didn't know it was physically possible to eat that much in one day. Bravo, you beast."),
            CalorieCommentary(title: "Massive overshoot", message: "You ate like you're hibernating for the next three decades."),
            CalorieCommentary(title: "Massive overshoot", message: "Your diet plan is officially in witness protection. What a glorious disaster.")
        ]
    }
}
