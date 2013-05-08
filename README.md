<div align="center"> <h1>WELCOME TO ACHIEVE<h1> </div>
<br/><br/>

<div align="center"><h2><strong>Getting Started</strong></h2></div>
Hey there. If you're reading this, it is likely you are looking for an Achievements solution for AS3. **Well you've found it!**. This Achievement API offers features you'd expect from one, and it has high flexibility, allowing you to customise it to how you want to. To get started you should:

----

- Download the files from the Repository.
- Link the 'Achievement.swc' to your AS3 project.
- If you use Starling, extract the 'DefaultStarlingNotification.as' into your project.

<br/><br/><br/><br/>

<div align="center"><h2><strong>Usage</strong></h2></div>

<h3>Creation and Initialization</h3>
The code in Achievement is **very** simple. Now, lets start with loading the Achievement Manager:

<pre><code>import achievement.core.AchievementManager;

private var achievementManager:AchievementManager;

function myFunction()
{
	achievementManager = AchievementManager.getInstance();
	
	// Create a notifier: ( stage, theme, alignment, delay, speed )
	var notifier:DefaultUnlockNotification = new DefaultUnlockNotification( stage, NotificationTheme.Dark, NotificationAlign.TOP);

	// Set the notifier that appears when a Medal is unlocked.
	achievementManager.notifier = new DefaultUnlockNotification();

	// Set the storage for when Medals and Properties are stored.
	achievementManager.storage = new DefaultLocalStorage();

	// Set the function to call when a Medal is unlocked.
	achievementManager.onUnlock = onUnlockMedal;

	// Set to DevMode so you don't save Medals / Properties every run.
	achievementManager.devMode = true;
}

function onUnlockMedal( medal:Medal ):void
{
	trace( medal.name + " was just unlocked!" );
}

</code></pre>

This will be updated soon.
