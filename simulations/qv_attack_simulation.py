import matplotlib.pyplot as plt
import numpy as np

# Simulate Token Holdings (Whale vs Community)
tokens = np.array([10, 20, 30, 50, 100, 500, 1000, 5000]) # Last entry is a "Whale"
voter_ids = [f"Voter {i+1}" for i in range(len(tokens))]

# 1-Token-1-Vote Model
linear_voting_power = tokens

# Quadratic Voting Model (Votes = sqrt(Tokens), Cost = Votes^2)
quadratic_voting_power = np.sqrt(tokens)

# Normalization for comparative plot
linear_share = (linear_voting_power / np.sum(linear_voting_power)) * 100
quadratic_share = (quadratic_voting_power / np.sum(quadratic_voting_power)) * 100

plt.figure(figsize=(10, 5))
x = np.arange(len(voter_ids))
width = 0.35

plt.bar(x - width/2, linear_share, width, label='1-Token-1-Vote (% Share)', color='#d9534f')
plt.bar(x + width/2, quadratic_share, width, label='Quadratic Voting (% Share)', color='#5cb85c')

plt.xlabel('Participant Distribution')
plt.ylabel('Governance Influence (%)')
plt.title('Whale Dominance Suppression: Linear vs Quadratic Voting')
plt.xticks(x, voter_ids)
plt.legend()
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig('simulations/whale_suppression_plot.png')
print("Simulation complete. Chart saved to simulations/whale_suppression_plot.png")