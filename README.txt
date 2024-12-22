'HUME: AN OBJECT ORIENTED COMPONENT LIBRARY FOR GENERIC MODULAR MODELLING OF DYNAMIC SYSTEMS '

Any model based on this library consists of one main model module, implemented in a class called ‘Tmod’ and a number of sub-models. 

The main model is responsible for the control of the simulation, single or multiple runs, and also implements methods like calculating basic statistics and parameter estimation based on the Levenberg-Marquardt method.
All sub-models have to be derived from the base class TsubMod’ which contains dynamic lists of state variables, variables, parameters and ‘external values’, i.e. values needed from outside the sub-model. The information exchange between the sub-models through ‘external values’ 
is flexible, since it is simply based on string identities between the information needed and information located in any other  or input file. This technique allows exchange of sub-models through ‘drag and drop’ without any changes in  source code even for a changing number and order of parameters, as long as the necessary input parameters to the sub-model can be found anywhere else in the model. 
A graphical user interface based on the general data structure supports control of parameter values, initial values and allows ' +
input of measured data. Based on these fundamental classes a component hierarchy has been and is still further developed, including several components for dry matter production, plant development, 
dry matter partitioning, root growth of plants as well as modules for soil water and soil nitrogen budget. 