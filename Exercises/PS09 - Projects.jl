### A Pluto.jl notebook ###
# v0.19.14

using Markdown
using InteractiveUtils

# ╔═╡ fc0426fc-d2b6-4751-9c48-ecf31a7b5a3b
html"""
 <! -- this adapts the width of the cells to display its being used on -->
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
	}
</style>
"""

# ╔═╡ 5126163e-0f60-4712-97fd-5a085af91744
md"""
# 2022 project ideas
## Renewable energy production
Wind farms are used to generate renewable energy. Both wind direction and wind strength are variable. To account for this, one can adjust the orientation of the wind turbines so that they are perpendicular to the wind direction. An undesirable effect of this is that one turbine may be in the wake of another. As a result, the airflow received by the downstream turbine is typically more turbulent and its average speed is lower, reducing its efficiency. Turning the upstream turbine slightly (yaw angle) can attenuate this downstream effect. The efficiency of a turbine that is not perpendicular to the wind direction is naturally lower. This leads to an overall optimization problem where one has to dynamically control the different wind turbines taking into account the current wind direction.

### References:
* [Replacing wakes with streaks in wind turbine arrays](https://onlinelibrary.wiley.com/doi/full/10.1002/we.2577)
* [Application of a LES technique to characterize the wake deflection of a wind turbine in yaw](https://onlinelibrary.wiley.com/doi/epdf/10.1002/we.380)
* [Measurements on a Wind Turbine Wake: 3D Effects and Bluff Body Vortex Shedding](https://onlinelibrary.wiley.com/doi/epdf/10.1002/we.156)


## Renewable energy production (2)
Hydroelectric is another form of renewable energy. Water reservoirs are created by placing one or multiple dams on a river. These reservoirs drive a turbine which powers a generator. There are multiple challenges involved with hydroelectric power. The rainfall or water supply is seldom constant over the year. Placing multiple (not coordinated) dams on a river can have a large impact on the downstream ecosystems, power generation and flow. Proper management of the systems of dams on the network can lead to substantial increases in overall power generation.

### References:
* [Forecast-informed hydropower optimization at long and short-time scales for a multiple dam network](https://aip.scitation.org/doi/abs/10.1063/1.5124097)
* [Optimal Control Method of Electric Power Generation in Multi Level Water Dams](https://link.springer.com/chapter/10.1007/978-3-642-16444-6_42)
* [Application of the Harmony Search optimization algorithm for the solution of the multiple dam system scheduling](https://link.springer.com/article/10.1007/s11081-011-9183-x)

## Renewable energy production (3)
Solar energy is becoming ever more visible in our environment. The optimal placement and configuration of a solar panel installation is not so trivial. Different effect play a role such as shading, panel orientation, solar angle evolution. Given a specific case, you could consider how to develop the optimal layout (accounting for seasonal variability). 

### References:
* [Spatial layout optimization for solar photovoltaic (PV) panel installation](https://www.sciencedirect.com/science/article/abs/pii/S0960148119319718)
* [An optical-energy model for optimizing the geometrical layout of solar photovoltaic arrays in a constrained field](https://www.sciencedirect.com/science/article/abs/pii/S0960148119319123)
* [Solar Array System Layout Optimization for Reducing Partial Shading Effect](http://przyrbwn.icm.edu.pl/APP/PDF/130/a130z1p014.pdf)


## Optimal deployment of law enforcement forces
During large scale events (e.g. sport events, european summit, protest) additional law enforcement forces are deployed. Just as in a military context, the form of deployment of troops can have a major impact on the successful control of a mass of people. Possibly historical data can be used for this (cooperation police Antwerp). 

### References:
* [Devising and Optimizing Crowd Control Strategies Using Agent-Based Modeling and Simulation](https://ieeexplore.ieee.org/document/9108875)
* [Simulating Crowd Behavior Using Artificial Potential Fields: An Agent-Based Simulation Approach](https://jstinp.um.ac.ir/article_42613_592bf75c5efc86ff6bcb6dfca776914b.pdf)
* [Crowd Simulation](https://link.springer.com/content/pdf/10.1007/978-3-319-65202-3.pdf)

## CCTV camera placement
One of the means used to deter crime and to detect traffic violations are CCTV cameras. The optimal placement of these cameras is a challenge. (cooperation police Antwerp).

### References:
* [On the real-world applicability of state-of-the-art algorithms for the optimal camera placement problem](https://ieeexplore.ieee.org/abstract/document/8820295)
* [On the optimal placement of cameras for surveillance and the underlying set cover problem](https://www.sciencedirect.com/science/article/abs/pii/S1568494618305829)

## DES for logistics
Discrete event simulation can be used in multiple domains of logistics (in the broad sense). For a specific application you could consider this approach.

### References:
* [Discrete event simulation of multimodal and unimodal transportation in the wood supply chain: a literature review](https://www.silvafennica.fi/article/9984/author/18687)
* [Predicting the effect of nurse–patient ratio on nurse workload and care quality using discrete event simulation](https://sci-hub.st/https://doi.org/10.1111/jonm.12757)
* [Modeling Electric Vehicle Charging Demand with the Effect of Increasing EVSEs: A Discrete Event Simulation-Based Model](https://www.mdpi.com/1996-1073/14/13/3734)
* [Using discrete-event simulation to compare congestion management initiatives at a port terminal](https://www.sciencedirect.com/science/article/abs/pii/S1569190X21000769)
* [Modeling and discrete event simulation in industrial systems considering consumption and electrical energy generation](https://www.sciencedirect.com/science/article/abs/pii/S0959652619309576)
* [Full-Scale Discrete Event Simulation of an Automated Modular Conveyor System for Warehouse Logistics](https://link.springer.com/chapter/10.1007/978-3-030-29996-5_4)

## Cellular automata
Cellular automata (cf. Conway's game of life) have been around for a while. At the same time, they still are being used in research for different types of applications.

### References:
* [A review of assessment methods for cellular automata models of land-use change and urban growth](https://www.tandfonline.com/doi/abs/10.1080/13658816.2019.1684499)
* [Cellular automata for simulating land-use change with a constrained irregular space representation: A case study in Nanjing city, China](https://journals.sagepub.com/doi/abs/10.1177/2399808320949889)
* [Modelling urban change with cellular automata: Contemporary issues and future research directions](https://journals.sagepub.com/doi/full/10.1177/0309132519895305)
* [A Modified Cellular Automaton Model for Accounting for Traffic Behaviors during Signal Change Intervals](https://www.hindawi.com/journals/jat/2018/8961454/)
* [On the consistency of urban cellular automata models based on hexagonal and square cells](https://journals.sagepub.com/doi/abs/10.1177/2399808319898501)
* [Modeling and analyzing malware diffusion in wireless sensor networks based on cellular automaton](https://journals.sagepub.com/doi/full/10.1177/1550147720972944)

## Pedestrian dynamics
Simple mathematical model for pedestrian dynamics can capture a number of features that are observed in actual pedestrian flows on walkways. For example, when obstacles get in their way, either physical obstacles or other pedestrians, walkers experience a repulsive social force, that alters their velocity and current direction to avoid collision. This alone is sufficient to produce a variety of patterns that are reminiscent of actual pedestrian dynamics. The explorable is a simplified variant of a series of beautiful models introduced by Dirk Helbing that have found a wide range of application, e.g. panic dynamics, crowd turbulence, traffic jams and more.

### References
* [Social force model for pedestrian dynamics](https://journals.aps.org/pre/abstract/10.1103/PhysRevE.51.4282)
* [Simulating dynamical features of escape panic](https://www.nature.com/articles/35035023)
* [Modelling the evolution of human trail systems](https://www.nature.com/articles/40353)
* [Social Self-Organization](https://link.springer.com/book/10.1007/978-3-642-24004-1)
"""

# ╔═╡ 023da279-7a42-4cb1-addb-613d1363a282
md"""
# 2021 project ideas:
Below you can find a list of possible projects. Almost all of these are described in a very generic way and will require some research on your behalf. Some background and/or similar studies are provided for each project, most of these being more complex than what is expected of you.

**Aim of the project**:
1. Describe the setting or problem
2. Describe the desired outcome of the study
3. Describe the model you built, including its limitations and accepted hypotheses. 
4. Describe your analysis
5. Describe the outcome or suggestions

Note that for a project with a deterministic outcome, the use of simulation might not be required.
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
md"""
## Chemistry
In the various chemistry courses, you have studied the reactions between molecules by means of kinetics. A reaction was modelled using a differential equation. However, it is also possible to model kinetics using stochastic methods. 

### Possible projects
Compare a stochastic model  (there are multiple in the reference) with a numerical method that you already know for some known reactions. In addition, use an optimisation method to fine-tune your reaction.

### References
* [Stochastic chemical kinetics](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5425731/)
"""

# ╔═╡ 57e9e568-4bb7-43d1-91cf-0711cc2fa905
md"""
## Finance
Modeling and simulation is widely used in the financial sector. Different techniques can be used.
### Possible projects
* **Portfolio optimisation of crypto currencies in combination with discrete even simulation**: We have already briefly discussed portfolio optimisation in the practical applications. However, the crypto market is much more volatile, so here it may be worthwhile to combine these optimisations with discrete event simulation and real data.
* **Insurance solvency**: Use Monte Carlo simulation or another suited method for a specific insurance to find an optimal balance between insurance premium and solvency.
* **Global trade embargo effects:** In today's world, nations are less likely to declare war on another country, but first try to achieve their goals through diplomatic or economic means. The global trade network has been extensively studied and data is freely available. Study the effect of a trade embargo on a particular country and consider possible unexpected alliances (where you can consider trade as an optimisation problem).
### References
* [Solvency ratio](https://en.wikipedia.org/wiki/Solvency_ratio)
* [Monte Carlo in insurance](https://www.researchgate.net/publication/332637928_Monte_Carlo_Methods_for_Insurance_Risk_Computation)
* [World Trade Network](https://www.researchgate.net/publication/23786718_The_World_Trade_Network)
* [World Trade Network dataset](http://www.cepii.fr/cepii/en/bdd_modele/presentation.asp?id=27), requires free registration, holds all network data.
"""

# ╔═╡ 2e4860bd-b74b-4671-8e57-c6849bc63d88
md"""
## Logistics
Supply chain optimisation and the optimal use of personnel or resources can significantly increase the efficiency of a logistics depot. These problems can be solved with linear programming, but it is often difficult to reach a solution because these problems are typically NP-hard. As a solution, either heuristics (cf. next year) or discrete event simulation is used.

### Possible projects
- **Personnel tasking**: given a specific warehouse, increase efficiency by optimising the tasks each person is executing.
- **Warehouse layout**: given a set of products and historical order data, optimise warehouse or grocery store layout for highest possible output (e.g. something similar to collect and go from the perspective of the store personnel)
- **Seaport operations**: In a cargo port, there are a multitude of actors at work such as pilots, ships, cranes, trains, trucks, etc.  In the context of efficient use of resources, it is interesting to simulate this in order to identify possible bottlenecks in different scenarios.  If necessary, study a part of a Belgian port.
### References
- [complete project personnel optimisation](https://www.mdpi.com/1999-4893/13/12/326)
- [data source](https://www.kaggle.com/msp48731/frequent-itemsets-and-association-rules/data)
- [seaport operations](https://sci-hub.st/https://doi.org/10.1177%2F003754979807000401)
- [layout optimisation](https://sci-hub.st/https://doi.org/10.1111/itor.12852)
"""

# ╔═╡ 4357e4be-1005-470f-978b-90844dd31b1a
md"""
## Healthcare
Within the healthcare sector there are a lot of use cases for discrete event simulation.

### Possible projects
get creative.
### References
- [overview paper](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7491890/)
- [staffing a neonatal ICU](https://journals.sagepub.com/doi/pdf/10.1177/1460458216628314)
- [capacity planning (COVID)](https://arxiv.org/abs/2012.07188)
"""

# ╔═╡ 88b57987-b284-41a7-8c35-3b29a0436d0f
md"""
## Biology
Simulation can also be used in biology.


### References:
- [evolution of a virus](https://academic.oup.com/ve/article/5/1/vez003/5372481)
- [evolution of a virus bis](https://sci-hub.st/https://doi.org/10.1007/s11538-018-00550-4)
"""

# ╔═╡ 72df832c-442f-4693-9953-df873951a1db
md"""
## Energy grid management
Managing the electricity grid is a major challenge. 
### Possible projects

### References
- [Introduction to electricity markets](https://www.e-education.psu.edu/ebf483/node/816)
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.2"
manifest_format = "2.0"
project_hash = "da39a3ee5e6b4b0d3255bfef95601890afd80709"

[deps]
"""

# ╔═╡ Cell order:
# ╟─fc0426fc-d2b6-4751-9c48-ecf31a7b5a3b
# ╟─5126163e-0f60-4712-97fd-5a085af91744
# ╟─023da279-7a42-4cb1-addb-613d1363a282
# ╟─42968b6f-a86f-48dd-b354-d06dfd53624c
# ╟─d3195ce3-cc34-458f-a526-f346591b34b2
# ╟─8bc9e310-3151-4c49-b009-04b4cc1a4a84
# ╟─279eda92-e1cf-480e-a093-e17625046125
# ╟─cb784ac1-7dde-4163-a325-379f87ccb18b
# ╟─a7659bd3-796b-4155-b01f-1d9ef6b42f12
# ╟─57e9e568-4bb7-43d1-91cf-0711cc2fa905
# ╟─2e4860bd-b74b-4671-8e57-c6849bc63d88
# ╟─4357e4be-1005-470f-978b-90844dd31b1a
# ╟─88b57987-b284-41a7-8c35-3b29a0436d0f
# ╟─72df832c-442f-4693-9953-df873951a1db
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
