### A Pluto.jl notebook ###
# v0.16.1

using Markdown
using InteractiveUtils

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

# ╔═╡ 65c30d33-de0e-410d-afa9-9e0e84431012
md"""input ben:
- risicomodellen gecombineerd met discreet event + bayesiaans (covid + splitsen)
- 
"""

# ╔═╡ 79db607a-8af7-4f60-a339-0e27cd6edf1f
md"""
## General topic

### Possible projects

### References
"""

# ╔═╡ 3117a9ed-4577-47fb-bc7f-54fb9572e313


# ╔═╡ Cell order:
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
# ╠═65c30d33-de0e-410d-afa9-9e0e84431012
# ╠═79db607a-8af7-4f60-a339-0e27cd6edf1f
# ╠═3117a9ed-4577-47fb-bc7f-54fb9572e313
