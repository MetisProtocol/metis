# Metis(WIP)

Metis Protocol is a synergy of governance mechanism (Layer 1) and collaboration framework (Layer 2) to upgrade and empower DApps (DAOs) to better govern their community.

# Features
1. Leverage Staking and Pullback as the foundation of the governance mechanism
- Staking: commitment of the collaborators to perform as their promise
- Pullback mechanism: punish the collaborator who couldn't fulfill his/her promise

2. Integrate Layer 1 governance with Layer 2 collaboration implementation
- OR side chain: as a collaboration environment, where collaborators can negotiate (not vote) to reach the consensus, call microservice tools to collaborate, and store all the collaboration activities and deliverables onto the time-stamped Wiki for future validation purpose
- Layer 2 to layer 1: the state change of the OR side chain (Layer 2) will call Meta Staking Contract (Layer 1) to allocate incentives (tasks accomplished) or pull back the staking for Arbitration (disputes arose)

3. Microservices Integration
- Extending the smart contracts
- Fast deployment
- High scalability

# Metis Layer 2 Construct
- Based on Optimistic Rollups
- Specialized in Collaboration
- L1 <> L2 communication
- Permissioned Network
- Security and Privacy

# Metis Optimistic Rollup Roadmap
Milestone 1: Metis Token deposit/withdraw, permissioned aggregator access and fraud penalty adjustment
- L1 Metis Token bridge contract
- OVM tweak for Metis Token deposit
- Integrate L1 bridge contract with the aggregator node 
- L1 permission contract 
- Integrate permissions with aggregator node
- OVM tweak for Metis Token withdraw
- L2 token management contract, supporting Metis Token only
- Add value limit to the OVM transactions. Aggregator will only accept transactions within its bond limit

Milestone 2: Multi token deposit/withdraw support
- Metis bridge contract to support multiple tokens
- OVM tweak for multi token deposit/withdraw
- L2 token management contract supports multiple tokens

Milestone 3: the most scalable, accessible and secure collaborate platform
- Separate storage for confidential data
- Extra layer of encryption on confidential data
- Data scrambler for confidential data.

