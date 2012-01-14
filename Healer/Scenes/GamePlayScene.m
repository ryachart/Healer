    //
//  GamePlayScene.m
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GamePlayScene.h"
#import "RaidView.h"
#import "PlayerSpellButton.h"
#import "BossHealthView.h"
#import "PlayerMoveButton.h"


@interface GamePlayScene ()
//Data Models
@property (retain) Raid *raid;
@property (retain) Boss *boss;
@property (retain) Player *player;
@end

@implementation GamePlayScene
@synthesize activeEncounter;
@synthesize raid;
@synthesize boss;
@synthesize player;
@synthesize raidView;
@synthesize spellView1, spellView2, spellView3, spellView4;
@synthesize bossHealthView, playerHealthView, playerEnergyView, playerMoveButton, playerCastBar;
@synthesize alertStatus;
-(id)initWithRaid:(Raid*)raidToUse boss:(Boss*)bossToUse andPlayer:(Player*)playerToUse
{
    if (self = [super init]){
        self.raid = raidToUse;
        self.boss = bossToUse;
        self.player = playerToUse;
        
        //CACHE SOUNDS
        AudioController *ac = [AudioController sharedInstance];
        for (Spell* aSpell in [player activeSpells]){
            [[aSpell spellAudioData] cacheSpellAudio];
        }
        [ac addNewPlayerWithTitle:CHANNELING_SPELL_TITLE andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/Channeling" ofType:@"wav"]]];
        [ac addNewPlayerWithTitle:OUT_OF_MANA_TITLE andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/OutOfMana" ofType:@"wav"]]];
	}
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)onEnter {
    [super onEnter];
	
	for (int i = 0; i < [[player activeSpells] count]; i++){
		switch (i) {
			case 0:
				[spellView1  setSpellData:[[player activeSpells] objectAtIndex:i]];
				[spellView1 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
				break;
			case 1:
				[spellView2 setSpellData:[[player activeSpells] objectAtIndex:i]];
				[spellView2 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
				break;
			case 2:
				[spellView3 setSpellData:[[player activeSpells] objectAtIndex:i]];
				[spellView3 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
				break;
			case 3:
				[spellView4 setSpellData:[[player activeSpells] objectAtIndex:i]];
				[spellView4 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
				break;
			default:
				break;
		}
	}
	
	
	[raidView spawnRects];
	NSMutableArray *raidMembers = [raid raidMembers];
	selectedRaidMembers = [[NSMutableArray alloc] initWithCapacity:5];
	for (RaidMember *member in raidMembers)
	{
		RaidMemberHealthView *rmhv = [[RaidMemberHealthView alloc] initWithFrame:[raidView vendNextUsableRect]];
		//NSLog(@"Vended Rect: %1.1f", (float)CGRectGetWidth([rmhv frame]));
		[rmhv setMemberData:member];
		[rmhv setInteractionDelegate:(RaidMemberHealthViewDelegate*)self];
		[raidView addRaidMemberHealthView:rmhv];
	}
	[bossHealthView setBossData:boss];
	[playerHealthView setMemberData:player];
	[playerHealthView setInteractionDelegate:(PlayerHealthViewDelegate*)self];
	[playerEnergyView setChannelDelegate:(ChannelingDelegate*)self];
	
	
	//The timer has to be scheduled after all the init is done!
    [self schedule:@selector(gameEvent:)];
}

-(void)thisMemberSelected:(RaidMemberHealthView*)hv
{
	//NSLog(@"You selected a raidMember");
	if ([[hv memberData] isDead]) return;
	if ([selectedRaidMembers count] == 0){
		[selectedRaidMembers addObject:hv];
		[hv setColor:ccc3(0, 0, 255)];
	}
	else if ([selectedRaidMembers objectAtIndex:0] == hv){
		//Here we do nothing because the already selected object has been reselected
	}
	else if ([selectedRaidMembers objectAtIndex:0] != hv){
		RaidMemberHealthView *currentTarget = [selectedRaidMembers objectAtIndex:0];
		if ([currentTarget isTouched]){
			[selectedRaidMembers addObject:hv];
			[hv setColor:ccc3(255, 0, 255)];
		}
		else{
			[currentTarget setColor:[currentTarget defaultBackgroundColor]];
			[selectedRaidMembers removeObjectAtIndex:0];
			[selectedRaidMembers insertObject:hv atIndex:0];
            [hv setColor:ccc3(0, 0, 255)];
		}
		
	}
}

-(void)thisMemberUnselected:(RaidMemberHealthView*)hv
{
	if (hv != [selectedRaidMembers objectAtIndex:0]){
		[selectedRaidMembers removeObject:hv];
		[hv setColor:[hv defaultBackgroundColor]];
	}
	
}

-(void)playerSelected:(PlayerHealthView *)hv
{
	if ([[hv memberData] isDead]) return;
	if ([selectedRaidMembers count] == 0){
		[selectedRaidMembers addObject:hv];
		[hv setBackgroundColor:[UIColor blueColor]];
	}
	else if ([selectedRaidMembers objectAtIndex:0] == hv){
		//Here we do nothing because the already selected object has been reselected
	}
	else if ([selectedRaidMembers objectAtIndex:0] != hv){
		PlayerHealthView *currentTarget = [selectedRaidMembers objectAtIndex:0];
		if ([currentTarget isTouched]){
			[selectedRaidMembers addObject:hv];
			[hv setBackgroundColor:[UIColor purpleColor]];
		}
		else{
			[currentTarget setBackgroundColor:[currentTarget defaultBackgroundColor]];
			[selectedRaidMembers removeObjectAtIndex:0];
			[selectedRaidMembers insertObject:hv atIndex:0];
			[hv setBackgroundColor:[UIColor blueColor]];
		}
		
	}
}
-(void)playerUnselected:(PlayerHealthView *)hv
{
	if (hv != [selectedRaidMembers objectAtIndex:0]){
		[selectedRaidMembers removeObject:hv];
		[hv setBackgroundColor:[hv defaultBackgroundColor]];
	}
	
}

-(void)spellButtonSelected:(PlayerSpellButton*)spell
{
	if ([selectedRaidMembers count] > 0 && [selectedRaidMembers objectAtIndex:0] != nil){
		NSMutableArray *targets = [NSMutableArray arrayWithCapacity:[selectedRaidMembers count]];
		for (RaidMemberHealthView *healthView in selectedRaidMembers){
			[targets addObject:[healthView memberData]];
		}
		
		if ([[spell spellData] conformsToProtocol:@protocol(Chargable)]){
			if ([player spellBeingCast] == nil){
				[(Chargable*)[spell spellData] beginCharging:[NSDate date]];
				[spell setColor:ccc3(150, 150, 0 )];
			}
		}
		else{
			[player beginCasting:[spell spellData] withTargets:targets];
		}
	}
}

-(void)spellButtonUnselected:(PlayerSpellButton*)spell{
	if ([selectedRaidMembers count] > 0 && [selectedRaidMembers objectAtIndex:0] != nil){
		NSMutableArray *targets = [NSMutableArray arrayWithCapacity:[selectedRaidMembers count]];
		for (RaidMemberHealthView *healthView in selectedRaidMembers){
			[targets addObject:[healthView memberData]];
		}
	
		if ([[spell spellData] conformsToProtocol:@protocol(Chargable)]){
			if ([(Chargable*)[spell spellData] chargeStart] != nil){
				[(Chargable*)[spell spellData] endCharging:[NSDate date]];
				[player beginCasting:[spell spellData] withTargets:targets];
				[spell setColor:ccc3(255, 255, 255)];
			}
		}
	}
}


-(void)gameEvent:(ccTime)deltaT
{
	//NSLog(@"Game Event!");
	//Data Events
	NSMutableArray *raidMembers = [raid raidMembers];
	NSInteger survivors = 0;
	for (RaidMember *member in raidMembers)
	{
		if (![member isDead]){
			[member combatActions:boss raid:raid thePlayer:player gameTime:deltaT];
			survivors++;
		}
		else {
			//if ([
		}

	}
	[boss combatActions:player theRaid:raid gameTime:deltaT];
	if ([playerMoveButton isMoving]){
		[player disableCastingWithReason:CastingDisabledReasonMoving];
		[player setPosition:[player position]+1];
	}
	else {
		[player enableCastingWithReason:CastingDisabledReasonMoving];
	}

	
	[player combatActions:boss theRaid:raid gameTime:deltaT];
	//Update UI
	[raidView updateRaidHealth];
	[bossHealthView updateHealth];
	[playerHealthView updateHealth];
	[playerCastBar updateTimeRemaining:[player remainingCastTime] ofMaxTime:[[player spellBeingCast] castTime]];
	[playerEnergyView updateWithEnergy:[player energy] andMaxEnergy:[player maximumEnergy]];
	[alertStatus setString:[player statusText]];
	[spellView1 updateUI];
	[spellView2 updateUI];
	[spellView3 updateUI];
	[spellView4 updateUI];
	
	//Determine if there will be another iteration of the gamestate
	if (survivors == 0)
	{
//		if ([self viewControllerToBecome] == nil){
//			[self.navigationController	popViewControllerAnimated:YES];
//		}
//		else {
//			[self.navigationController popToViewController:viewControllerToBecome animated:YES];
//		}
		UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"Your Raid is dead" delegate:nil cancelButtonTitle:@"And so are you" otherButtonTitles:nil];
		[failureAlert show];

	}
	if ([player isDead]){
//		if ([self viewControllerToBecome] == nil){
//			[self.navigationController	popViewControllerAnimated:YES];
//		}
//		else {
//			[self.navigationController popToViewController:viewControllerToBecome animated:YES];
//		}
//		UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"You have died" delegate:nil cancelButtonTitle:@"Be more careful" otherButtonTitles:nil];
//		[failureAlert show];
//		[gameLoopTimer invalidate];
	}
	if ([boss isDead]){
		[activeEncounter characterDidCompleteEncounter];
//		if ([self viewControllerToBecome] == nil){
//			[self.navigationController	popViewControllerAnimated:YES];
//		}
//		else {
//			[self.navigationController popToViewController:viewControllerToBecome animated:YES];
//		}
//		UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:@"WIN" message:@"You completed the mission!" delegate:nil cancelButtonTitle:@"Onto something darker.." otherButtonTitles:nil];
//		[failureAlert show];
//		[gameLoopTimer invalidate];
	}
	//NSLog(@"gameEventFired");
}

-(void)beginChanneling{
	[player startChanneling];
}

-(void)endChanneling{
	[player stopChanneling];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (void)dealloc {
    [super dealloc];
	AudioController *ac = [AudioController sharedInstance];
	for (Spell* aSpell in [player activeSpells]){
		[[aSpell spellAudioData] releaseSpellAudio];
	}
	[ac removeAudioPlayerWithTitle:CHANNELING_SPELL_TITLE];
	[ac removeAudioPlayerWithTitle:OUT_OF_MANA_TITLE];
}


@end
