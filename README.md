# Stanford-CS193P-Project-4-Fall-2017
### A (partial) solution for programming assignment 4

This project implements the majority of the requirements layed out in Assignment IV: Animated Set of the excellent Stanford iOS Development cource. The course is available for free on [iTunes U](https://itunes.apple.com/us/course/developing-ios-11-apps-with-swift/id1309275316).

The game Set is described [here](https://en.wikipedia.org/wiki/Set_(game)).

For a 'real' game there are few things that should or could to be changed:
- drop the rotation in the fly-out phase of the card animations - it makes the shadows look wrong. Alternatively, drop the shadow, at least during the animation.
- animate the changing of the score etc info at the bottom of the screen
- devise a way for the user to see all possible hints
- reward the user for finding several or all of multiple solutions
- add a time component to the scoring, rewarding speed
- reward the user for picking more 'difficult' matches, where more or all of the traits are different in a match
- add some sort of visual indication of the height of the two card piles
- add a visual indicaton of the end of a game
- add some sort of a 'personal best' chart of scores
- add a feature to re-shuffle the open cards when the user shakes the device
- icon & launch screen

### How to play

Once you read the basic [rules](https://en.wikipedia.org/wiki/Set_(game)) the user interface is hopefully somewhat obvious, maybe except:
- the Hint button shows only he last of any available matches.
- the Auto button lets you go through the game without too much effort. The intended use is mostly for debugging.
- the number labeled 'Δ' is the last score delta, i.e. the latest change to the score.

If you want to just play the Set game you should consider getting the offical [Set game](https://itunes.apple.com/us/app/set-mania/id775474270?mt=8).
