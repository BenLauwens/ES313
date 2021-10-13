### A Pluto.jl notebook ###
# v0.16.1

using Markdown
using InteractiveUtils

# ╔═╡ 023da279-7a42-4cb1-addb-613d1363a282
md"""
# 2021 project ideas:
Below you can find a list of possible projects. Almost all of these are described in a very generic way and will require some research on your behalf. Some background and/or similar studies are provided for each project, most of these being more complex than what is expected of you.
"""

# ╔═╡ 42968b6f-a86f-48dd-b354-d06dfd53624c
md"""
## Swarming (multiple projects)
The use of drone swarms has several applications in a military context. Drones can be equipped with different payloads such as high explosives, sensors (ISR), jammers, etc. Currently, all major military countries are conducting research on both the use of and the defense against drone swarms.

### Possible topics:
- **command and control (C2) of a drone swarm**: for the technology to be scalable, each element of the swarm should be cheap, so you will have a limited amount of control drones that are used for relaying communications with the HQ. The movement patterns of drones in different cases can be studied and optimised.
- **use of a drone swarm for ISR purposes**: drone swarms can be used to [gather intelligence](https://www.timesofisrael.com/in-apparent-world-first-idf-deployed-drone-swarms-in-gaza-fighting/) in addition to more traditional assets. Given a specific scenario and an ISR capacity, determine optimal use cases.
- **defense against a drone swarm**: given an adversarial drone swarm attack, determine optimal techniques of defense (weapon system and/or engagement method).
- **attack using a drone swarm**:  given an adversial defense system, determine optimal techniques/patterns/tactics to maximise the impact of the attack.

### References:
* [General info](https://www.vifindia.org/article/2020/april/27/drone-swarms-bracing-up-with-the-new-threat)
* [More details](http://unsworks.unsw.edu.au/fapi/datastream/unsworks:45320/SOURCE02?view=true)
"""

# ╔═╡ d3195ce3-cc34-458f-a526-f346591b34b2
md"""
## Mine hunting
Mine Counter Measure (MCM) is a general capability that can include several types of missions required to complete a specific operational intent:
- General or detailed survey to prepare Mine Warfare (MW) operations,
- Surveillance or exploration to assess Mine Warfare risk,
- Reconnaissance and Mine avoidance to avoid mine threat,
- Clearance to sanitize,
- Masking and jamming to prevent mine action,
- Provocation and discredit to deceive mine logic.

### Possible projects
- **optimise sweep patterns to maximise detection**: the detection probability of a mine depends on its position with respect to the sonar and the composition of the seabed. Simulate a minefield and try to optimise the sweeping settings to finetune the detection rate.
- **optimise mine field**: different types of (deep) sea mines exist. Given a set of mines, evaluate the composition/layout of a minefield for maximum effect.

### References
- [Synthetic Aperture and 3D Imaging for Mine Hunting Sonar](https://hal.archives-ouvertes.fr/hal-00504862/document)
- [Minhunting sonar perfomance](https://apps.dtic.mil/sti/pdfs/ADA342568.pdf)
- [Modern mines](https://cimsec.org/modern-naval-mines-not-your-grandfathers-weapons-that-wait/)
"""

# ╔═╡ 8bc9e310-3151-4c49-b009-04b4cc1a4a84
md"""
## Airfield destruction
Destroying or rendering unusable an enemy airfield can have a major impact on the course of a conflict (think of the Six Day War). Typically, ballistic missiles and cruise missiles are used, each with a different effect and a different cost. A military airfield usually has a defense system against missiles and rockets where the interception rate is different for each weapon system. 
### Possible project
Consider an airport with its different components: the runway, the critical infrastructure (POL + control tower) and the different airplanes. You could look at Kleine Brogel or Florennes air base for inspiration. Determine the effect of using a specific set of weapon systems (ballistic & guided munitions, with submunitions or not with different CEP) and consider the optimal/ideal/minimal configuration that allows you to take out the airfield.

### References
* [Defense systems](https://www.boeing.com/defense/missile-defense/)
"""

# ╔═╡ 279eda92-e1cf-480e-a093-e17625046125
md"""
## Digital communication

### Possible projects
* **TCP/IP**: simulate the TCP/IP model for data transfer and look up the limits with respect to data troughput for given hardware.
* **routing**: analyse how well routing works using different routing protocols on a (dynamic) network.
* **tactical radio network**: compare different scheduling algorithms to maximise data throughput in a tactical radio network.

### References
* [Basic on internet and IP routing, TCP/IP](https://www.khanacademy.org/computing/computers-and-internet/xcae6f4a7ff015e7d:the-internet)
* [Routing protocol](https://en.wikipedia.org/wiki/Routing_protocol)
* [Scheduling](https://en.wikipedia.org/wiki/Scheduling_(computing)#Scheduling_disciplines)
"""

# ╔═╡ cb784ac1-7dde-4163-a325-379f87ccb18b
md"""
## Fine-tuning a grading system
Some universities allow a student to fail a course and still be able to go to the next year or be exempt from retaking the exam. A mishap in an otherwise good course can be forgiven as a result. The "optimal" ground rules of such a system are far from trivial. After all, there are conflicting interests to be realized. One wishes, on the one hand, to limit the number of students who can abuse the system and, on the other hand, to ensure that the majority of students can benefit from the system. In addition, for practical reasons, one may wish to limit the overall number of resits.

### Possible project
By using historical data over several years, it is possible to establish a multinomial distribution that describes the results of students in an academic bachelor. You can use this input to adjust the parameters of your system, taking into account a conflicting desired results (e.g. $<1\%$ “freeloaders”, limiting number of resits, maximal fair pardons).

### References
"""

# ╔═╡ a7659bd3-796b-4155-b01f-1d9ef6b42f12


# ╔═╡ 72df832c-442f-4693-9953-df873951a1db
md"""
## Energy grid management
Managing the electricity grid is a major challenge. 
### Possible projects

### References
- [Introduction to electricity markets](https://www.e-education.psu.edu/ebf483/node/816)
"""

# ╔═╡ 65c30d33-de0e-410d-afa9-9e0e84431012
md"""input ben:
- risicomodellen gecombineerd met discreet event + bayesiaans (covid + splitsen)
- 
"""

# ╔═╡ 8a23e486-5f4e-4db3-8955-ac5a948203f1
md"""
## General topic

### Possible projects

### References
"""

# ╔═╡ 79db607a-8af7-4f60-a339-0e27cd6edf1f
md"""
## General topic

### Possible projects

### References
"""

# ╔═╡ 3117a9ed-4577-47fb-bc7f-54fb9572e313


# ╔═╡ 1e897cf4-18f5-11eb-2953-d1d83d41a044
md"""
# 2020 Project ideas:
Below you can find a list of possible projects. Almost all of these are described in a very generic way and will require some research on your behalf. Some background and/or similar studies are provided for each project, most of these being more complex than what is expected of you.

## Urban planning (multiple projects) (up to 3 projects)
A city evolves organically, but different policies can lead sometimes lead to unwanted effects. Simulation can be a welcome tool when dealing with city planning, as one can mitigate the problem of unintended consequences. 

For a cities you can consider the following actors in cities:
* households, which are subject to:
  - demographic processes (aging, migration, building integrity)
  - long-term choices (vehicle ownership, housing choice, workplace)
  - short term choices (routing, activities)
* governments provide:
  - land use regulations
  - infrastructure (transportation, water supply, waste management, parking space, schools...)
* developers impact the real estate:
  - land development
  - housing development
  - non-residential development (shopping centers)
* businesses:
  - economic processes: generate goods/trade
  - long-term impact: generate labor demand, mobility
  - short-term impact: movement of goods

### Possible cases
For a given city (provided some data is available e.g. [Brussels](https://opendata.brussels.be/page/home/) or from [StatBel](https://bestat.statbel.fgov.be/bestat/)) you could consider:
* The demographic evolution and it link to changing requirements for different services and optimal ways to deal with this. E.g. a growing population could lead to more children going to school. If you want to avoid overpopulation, you need to anticipate this by either increasing school capacity or by building new schools. On might look into priorities to allocation budgets
*  In order to limit traffic congestion a government might provide an incentive to stimulate car sharing and use of public transport. This will in turn lead to more demand, so public transport needs to be able to digest this increase. The overall effect of the stimulus should lead to less congested streets. One might again optimize to gain the largest possible effect given a limited budget
* You could look into the effect of [gentrification](https://en.wikipedia.org/wiki/Gentrification) on a (part of a) city.
* etc.
over a period of time that is appropriate for the topic you are covering. 

*Possible sources for inspiration*:
* https://urbansim.com/urbansim
* https://sustainability.asu.edu/dcdc/watersim/
* https://www.epfl.ch/labs/leso/transfer/software/citysim/
* https://datasmart.ash.harvard.edu/news/article/data-driven-insights-on-urban-water-systems-844
* https://bestat.statbel.fgov.be/bestat/crosstable.xhtml?view=0464e37a-da54-440a-a3e0-10f6b45b635a


## Disease spreading (2 projects)
The spread of a disease is not the always the same across different demographics. Given a demographic composition and the possible interactions between the different demographics, you can build a model that allows you to not only evaluate the expected evolution of the system, but also could provide an indication of the impact of specific measure. 

As long as you have a notion of the evolution of the disease, you could apply this on Influenza, Covid, STI's, Ebola etc.

For this project you could study vaccination campaigns, mitigation measures etc. Different scales and associated measures can also be considered (e.g. city/nation/global)

*Possible sources for inspiration*:
* https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6926909/
* https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4573360/
* (https://www.tableau.com/about/blog/2020/4/social-distancing-three-data-driven-simulations-will-show-you-just-how-important)

## Planning hospital staffing
Hospitals face the difficult challenge of designing shift schedules for their residents that satisfy demand, provide quality care, and are compliant with regulations restricting shift lengths. You could analyze the impact of different shift lengths on admitting capacity (i.e. the largest patient arrival rate sustainable by a given shift schedule) and the number of reassigned patients (i.e. the number of patients admitted temporarily by one doctor and then permanently transferred to a resident). Possible shift lengths could include:
* Long Shifts (LS): where residents work long shifts on alternating days
* Daily Admitting (DA): Daily Admitting (DA)

*Possible sources for inspiration*:
* https://dspace.mit.edu/handle/1721.1/92055 (Ch 6)

## Life cycle cost modeling
Consider the total ownership cost of a vehicle/machine/system. The system will without a doubt fail on one or more occasions. Given some reliability data and associated repair costs (and maybe downtime), you can identify different ownership strategies and determine an optimal one.

In the case of a single system (e.g. your own car), you could look at the optimal moment to replace a system. In the case of multiple systems (e.g. the busses of a public transport company) you could look into the trade-off between uptime (quality of service) and expenses (maintenance vs. replacement) with respect to the total budget.

*Possible sources for inspiration*:
* https://ascelibrary.org/doi/abs/10.1061/%28ASCE%29CO.1943-7862.0001816?af=R&
* https://www.researchgate.net/publication/316579564_How_Total_is_a_Total_Cost_of_Ownership 
* data from a car dealership (if available)

## Social security
Government policies have a large impact on the budget. Taxing specific items leads to more income, but the price increase also leads to reduced demand. On top of that, additional (desired) effects such as reducing long term health issues can occur.

You could analyze the effect of adding a health tax on sugary drinks or cigarettes on consumption and the associated additional gains due to lower prevalence of long term health issues (lung cancer, diabetes etc.)

*Possible sources for inspiration*:
* https://www.who.int/bulletin/volumes/94/4/15-164707/en/
* https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1003025
* https://www.cdc.gov/tobacco/data_statistics/fact_sheets/health_effects/tobacco_related_mortality/

## Social security
The United States is one of the only western countries that does not have universal healthcare and add the same time they spend the most of any country in the world on healthcare. Opponents argue that the wealthiest Americans and businesses would have to pay for the bulk of these added costs and that it would raise taxes on most Americans without reducing the total cost of healthcare.

Using data about disease prevalence and the associated treatment cost, you could compare two strategies: universal healthcare vs. individual payments or a combination of both. From a government standpoint, you could look into:
- the amount of taxes required for the system to be sustainable in the long term
- income distribution combined with disease prevalence and associated costs could provide an indication of the number of persons susceptible to having financial problems.

*Possible sources for inspiration*:
* https://link.springer.com/article/10.1007/s10198-018-0963-5#Abs1
* https://www.bfs.admin.ch/bfs/en/home/statistics/economic-social-situation-population/economic-and-social-situation-of-the-population/inqualities-income-ditribution/income-distribution.assetdetail.11467861.html

## Tactical (cognitive) radio networks
In modern military operations, communication is key. One option is to make use of cognitive Radio (CR), a system that can sense its environment and, without the intervention of the user, can adapt to the user's communications needs.

You could follow several approaches:
- Given an operational requirement, determine the capacities required
- Given a radio capacity, determine what the systems' limits are.

*Possible sources for inspiration*:
* http://www.sic.rma.ac.be/~scheers/Papers/SDR_ERRT2010.pdf
* https://apps.dtic.mil/sti/pdfs/AD1004297.pdf
* https://en.wikipedia.org/wiki/Cognitive_radio
* https://www.researchgate.net/publication/257676145_CogNS_A_Simulation_Framework_for_Cognitive_Radio_Networks


## Quantum mechanics
Quantum mechanics makes heavy use of probabilities. Make use of simulation to reproduce well known physics experiments that illustrate the principles of quantum mechanics such as:
- the double-slit experiment
- quantum Hall effect
_ ...

*Possible sourcess for inspiration*:
* physics course
* http://interactive.quantumnano.at

## Disaster management
The medical and emergency response following a mass casualty incident should be as good as possible. Consider a specific scenario and compare different strategies and policies in order to maximize the survivability of the victims.

You could consider a terrorist attack during a E.U. summit, an explosion (cf. Beirut). Possible aspects that you could include are victim triage and evacuation, accessibility for first responders, other actors on site such as firefighters of police for crowd control.

*Possible sources for inspiration*:
* https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5069323/
* https://cris.vub.be/files/41838791/VersionEditor_1_.pdf


## Fair ticket system policy
Large events such as Tomorrowland suffer from a very high demand and limited capacity. The experience of obtaining a ticket is similar to playing the lottery. At the start of the ticket sale, there is a peak in demand that the registration system needs to be able to handle. You could think about: 
- implementing a basic ticketing system
- some users will try to bypass the system by opening multiple browsers, analyzing the way the site works etc. You could look into how different strategies maximize the probability of obtaining a ticket
*Possible sources for inspiration*:
* https://webventures.tweakblogs.net/blog/14435/how-to-get-tomorrowland-tickets-a-technical-analysis

## Wargaming - submarine hunting
You could consider a scenario of a critical ship (e.g. a carrier or a commercial fleet) with a number of escort ships that hunt a submarine, which is placed in a patrol zone and is engaging these vessels. You could consider the following setting:
* Submarines try to sink all ships detected in the torpedo range
* Escort Ships search for the submarine, sharing its position to the other escort ships when it is detected

You could include
- sensor capabilities (e.g. sonar)
- places to hide by including relief (3D aspect)
- "quiet" mode for the submarine
- evasive maneuvers (P_hit/P_kill)

A possible topics of approach could be the critical ship's point of view (i.e. required escort size for survivability) <> submarine's point of view (tactics/sensors/weapon systems)

## Wargaming - Air power
Simulations can be used to plan air operations and determine the assets that need to be used in order to obtain a desired effect. You could consider:
- different types of targets
- different types of weapons with their specific performance
- performance of the avionics
- ground based air defense systems in addition to the hostile air force

*Possible sources for inspiration*:
* https://www.rand.org/content/dam/rand/pubs/notes/2008/N3566.pdf
* https://informs-sim.org/wsc14papers/includes/files/204.pdf
* https://sci-hub.st/10.2307/167374

## Nuclear Disaster management
Consider a scenario where a nuclear (dirty bomb) hits a city. The military is put in charge of the search and rescue mission. The following aspects could/should be considered:
* radiation levels of the victims
* decontamination and care facilities
* storage/grouping of injured/deceased persons (= additional source of radiation)
* radiation levels of the military personnel (exposure)
* city layout 

For a given setting you could determine the optimal strategy to sweep the zone and determine the required resources to make sure you limit you own losses.

## Supply chain
Simulates product delivery  a country or across Europe. The supply chain can include multiple manufacturing facilities, each of which has its own fleet of trucks. A large number of distributers place orders. 

You could consider:
- maximize capacity for different strategies, minimize cost for different strategies or combine both
- different supply methods e.g. when you need to wait for an order, use the nearest manufacturing facility <> use the first available
- 24/7 operation vs "9 to 5"
- nothing is free (e.g. storage, personnel, fuel etc.)
- locations could be represented as a weighted graph (maybe even a collection of weight distributions to account for traffic and time of day)


## Long term manpower planning
Based on ongoing research in the Dept.

*Possible source for inspiration*:
* https://www.researchgate.net/publication/333719869_Manpower_planning_using_simulation_and_heuristic_optimization


## Others
You can always come to use with your own project proposition. 




"""

# ╔═╡ Cell order:
# ╟─023da279-7a42-4cb1-addb-613d1363a282
# ╟─42968b6f-a86f-48dd-b354-d06dfd53624c
# ╟─d3195ce3-cc34-458f-a526-f346591b34b2
# ╟─8bc9e310-3151-4c49-b009-04b4cc1a4a84
# ╟─279eda92-e1cf-480e-a093-e17625046125
# ╟─cb784ac1-7dde-4163-a325-379f87ccb18b
# ╠═a7659bd3-796b-4155-b01f-1d9ef6b42f12
# ╠═72df832c-442f-4693-9953-df873951a1db
# ╠═65c30d33-de0e-410d-afa9-9e0e84431012
# ╠═8a23e486-5f4e-4db3-8955-ac5a948203f1
# ╠═79db607a-8af7-4f60-a339-0e27cd6edf1f
# ╠═3117a9ed-4577-47fb-bc7f-54fb9572e313
# ╟─1e897cf4-18f5-11eb-2953-d1d83d41a044
