# Weather Viewer - Luke E

This is a simple application written in Ruby using Sinatra that determines the user's location based on their IP address, gets the weather data for that location, and displays it.

## Installation
#### Prerequisites
The script requires Sinatra v3.0.4 or newer. If you don't already have it installed, install the "sinatra" gem with the following command:
`gem install sinatra`

The script also requires ruby 3.2.1 or newer.

#### Other Installation
No additional installation is required.

## Running
To run the script, simply navigate to the directory you cloned this git repository to and run the following command:
`ruby main.rb`

This will run the Sinatra application with a link at the bottom. To view the application, visit the link at the bottom of the command output. It will be something like: `localhost:4567`

## User Interface
#### Navigation
The Weather Viewer has 3 main panels.
![Screen Shot 2023-02-20 at 12 12 34 AM](https://user-images.githubusercontent.com/99271670/220014771-5ae55660-d871-4c60-b82c-9f74a9c4d93c.png)


To the left, it displays today's current temperature, an icon representing night, sunny, cloudy, partially cloudy, or raining, as well as the high/low temperatures for the current day.

The top right panel is the 7 day forecast. Each day contains an icon representing the cloud/rain conditions, as well as the high/low temps.

The bottom right panel is a bar graph representing the 7-day temperature highs and lows.

#### Updating Data
To update the data displaying on the screen, simply refresh the page. This will display the most up to date information.
