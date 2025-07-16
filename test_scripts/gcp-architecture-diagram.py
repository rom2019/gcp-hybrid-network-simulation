import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Rectangle, Circle, FancyArrowPatch
from matplotlib.patches import ConnectionPatch
import matplotlib.lines as mlines

# Create figure and axis
fig, ax = plt.subplots(1, 1, figsize=(20, 14))
ax.set_xlim(0, 20)
ax.set_ylim(0, 14)
ax.axis('off')

# Define colors
dev_color = '#4285F4'  # Google Blue
prod_color = '#EA4335'  # Google Red
vpn_color = '#34A853'  # Google Green
api_color = '#FBBC04'  # Google Yellow
network_color = '#E8F0FE'
subnet_color = '#E3F2FD'

# Title
ax.text(10, 13.5, 'Google Cloud Hybrid Network Architecture', 
        fontsize=24, fontweight='bold', ha='center')
ax.text(10, 13, 'On-Premises Simulation with Gemini API Access', 
        fontsize=16, ha='center', style='italic')

# Dev Project (On-premises simulation)
dev_project = FancyBboxPatch((0.5, 7), 8.5, 5.5,
                            boxstyle="round,pad=0.1",
                            facecolor=network_color,
                            edgecolor=dev_color,
                            linewidth=3)
ax.add_patch(dev_project)
ax.text(4.75, 12.2, 'Dev Project (On-Premises Simulation)', 
        fontsize=14, fontweight='bold', ha='center', color=dev_color)
ax.text(4.75, 11.8, 'Project ID: on-prem-sim-[random]', 
        fontsize=10, ha='center', style='italic')

# Dev VPC
dev_vpc = Rectangle((1, 8.5), 7.5, 3.2, 
                   facecolor=subnet_color, 
                   edgecolor=dev_color, 
                   linewidth=2)
ax.add_patch(dev_vpc)
ax.text(4.75, 11.4, 'Dev VPC (10.0.0.0/16)', 
        fontsize=12, fontweight='bold', ha='center')

# Dev Subnet
dev_subnet = Rectangle((1.5, 9), 6.5, 2.2, 
                      facecolor='white', 
                      edgecolor=dev_color, 
                      linewidth=1, 
                      linestyle='--')
ax.add_patch(dev_subnet)
ax.text(4.75, 10.9, 'Dev Subnet (10.0.1.0/24)', 
        fontsize=10, ha='center')

# Dev VM
dev_vm = FancyBboxPatch((2, 9.3), 2.5, 1.5,
                       boxstyle="round,pad=0.05",
                       facecolor='#E8F5E9',
                       edgecolor='#2E7D32',
                       linewidth=2)
ax.add_patch(dev_vm)
ax.text(3.25, 10.3, 'Dev Workstation', fontsize=10, fontweight='bold', ha='center')
ax.text(3.25, 10, 'e2-medium', fontsize=8, ha='center')
ax.text(3.25, 9.7, 'Debian 11', fontsize=8, ha='center')
ax.text(3.25, 9.5, 'No External IP', fontsize=8, ha='center', style='italic')

# Cloud NAT (Dev)
dev_nat = FancyBboxPatch((5.5, 9.3), 2, 1.5,
                        boxstyle="round,pad=0.05",
                        facecolor='#FFF3E0',
                        edgecolor='#F57C00',
                        linewidth=2)
ax.add_patch(dev_nat)
ax.text(6.5, 10.3, 'Cloud NAT', fontsize=10, fontweight='bold', ha='center')
ax.text(6.5, 10, 'dev-nat', fontsize=8, ha='center')
ax.text(6.5, 9.7, 'Auto IP', fontsize=8, ha='center')
ax.text(6.5, 9.5, 'All Subnets', fontsize=8, ha='center')

# Dev VPN Gateway
dev_vpn = Circle((4.75, 7.8), 0.6, 
                facecolor=vpn_color, 
                edgecolor='darkgreen', 
                linewidth=2)
ax.add_patch(dev_vpn)
ax.text(4.75, 7.8, 'VPN', fontsize=9, fontweight='bold', ha='center', va='center', color='white')
ax.text(4.75, 7, 'HA VPN Gateway', fontsize=9, ha='center')

# Prod Project (Gemini API)
prod_project = FancyBboxPatch((11, 7), 8.5, 5.5,
                             boxstyle="round,pad=0.1",
                             facecolor=network_color,
                             edgecolor=prod_color,
                             linewidth=3)
ax.add_patch(prod_project)
ax.text(15.25, 12.2, 'Prod Project (Gemini API)', 
        fontsize=14, fontweight='bold', ha='center', color=prod_color)
ax.text(15.25, 11.8, 'Project ID: gemini-api-prod-[random]', 
        fontsize=10, ha='center', style='italic')

# Prod VPC
prod_vpc = Rectangle((11.5, 8.5), 7.5, 3.2, 
                    facecolor=subnet_color, 
                    edgecolor=prod_color, 
                    linewidth=2)
ax.add_patch(prod_vpc)
ax.text(15.25, 11.4, 'Prod VPC (10.1.0.0/16)', 
        fontsize=12, fontweight='bold', ha='center')

# Prod Subnet
prod_subnet = Rectangle((12, 9), 6.5, 2.2, 
                       facecolor='white', 
                       edgecolor=prod_color, 
                       linewidth=1, 
                       linestyle='--')
ax.add_patch(prod_subnet)
ax.text(15.25, 10.9, 'Prod Subnet (10.1.1.0/24)', 
        fontsize=10, ha='center')

# Prod Test VM
prod_vm = FancyBboxPatch((12.5, 9.3), 2.5, 1.5,
                        boxstyle="round,pad=0.05",
                        facecolor='#FFEBEE',
                        edgecolor='#C62828',
                        linewidth=2)
ax.add_patch(prod_vm)
ax.text(13.75, 10.3, 'Prod Test VM', fontsize=10, fontweight='bold', ha='center')
ax.text(13.75, 10, 'e2-micro', fontsize=8, ha='center')
ax.text(13.75, 9.7, 'Debian 11', fontsize=8, ha='center')
ax.text(13.75, 9.5, 'Internal Only', fontsize=8, ha='center', style='italic')

# Cloud NAT (Prod)
prod_nat = FancyBboxPatch((16, 9.3), 2, 1.5,
                         boxstyle="round,pad=0.05",
                         facecolor='#FFF3E0',
                         edgecolor='#F57C00',
                         linewidth=2)
ax.add_patch(prod_nat)
ax.text(17, 10.3, 'Cloud NAT', fontsize=10, fontweight='bold', ha='center')
ax.text(17, 10, 'prod-nat', fontsize=8, ha='center')
ax.text(17, 9.7, 'Auto IP', fontsize=8, ha='center')
ax.text(17, 9.5, 'All Subnets', fontsize=8, ha='center')

# Prod VPN Gateway
prod_vpn = Circle((15.25, 7.8), 0.6, 
                 facecolor=vpn_color, 
                 edgecolor='darkgreen', 
                 linewidth=2)
ax.add_patch(prod_vpn)
ax.text(15.25, 7.8, 'VPN', fontsize=9, fontweight='bold', ha='center', va='center', color='white')
ax.text(15.25, 7, 'HA VPN Gateway', fontsize=9, ha='center')

# VPN Connection
vpn_connection = FancyArrowPatch((5.35, 7.8), (14.65, 7.8),
                                connectionstyle="arc3,rad=0",
                                arrowstyle='<->',
                                mutation_scale=20,
                                linewidth=3,
                                color=vpn_color)
ax.add_patch(vpn_connection)
ax.text(10, 8.2, 'HA VPN Tunnels (x2)', fontsize=10, fontweight='bold', ha='center', color=vpn_color)
ax.text(10, 7.9, 'BGP Sessions (ASN: 64512 ↔ 64513)', fontsize=9, ha='center')
ax.text(10, 7.6, 'IPsec Encrypted', fontsize=8, ha='center', style='italic')

# Google APIs section
google_apis = FancyBboxPatch((7, 4), 6, 2.5,
                            boxstyle="round,pad=0.1",
                            facecolor='#FFF9C4',
                            edgecolor=api_color,
                            linewidth=2)
ax.add_patch(google_apis)
ax.text(10, 6.2, 'Google APIs & Services', 
        fontsize=12, fontweight='bold', ha='center', color='#F57F17')

# Gemini API
gemini_api = FancyBboxPatch((7.5, 4.5), 2.5, 1.5,
                           boxstyle="round,pad=0.05",
                           facecolor='white',
                           edgecolor='#1976D2',
                           linewidth=2)
ax.add_patch(gemini_api)
ax.text(8.75, 5.5, 'Gemini API', fontsize=10, fontweight='bold', ha='center')
ax.text(8.75, 5.2, 'Vertex AI', fontsize=8, ha='center')
ax.text(8.75, 4.9, 'us-central1', fontsize=8, ha='center')
ax.text(8.75, 4.7, 'gemini-pro', fontsize=8, ha='center', style='italic')

# Private Google Access
pga = FancyBboxPatch((10.5, 4.5), 2.5, 1.5,
                    boxstyle="round,pad=0.05",
                    facecolor='white',
                    edgecolor='#7B1FA2',
                    linewidth=2)
ax.add_patch(pga)
ax.text(11.75, 5.5, 'Private Access', fontsize=10, fontweight='bold', ha='center')
ax.text(11.75, 5.2, 'Cloud DNS', fontsize=8, ha='center')
ax.text(11.75, 4.9, 'restricted.googleapis.com', fontsize=7, ha='center')
ax.text(11.75, 4.7, '199.36.153.8-11', fontsize=7, ha='center', style='italic')

# API connections
api_conn1 = FancyArrowPatch((4.75, 9), (8.75, 6),
                           connectionstyle="arc3,rad=0.3",
                           arrowstyle='->',
                           mutation_scale=15,
                           linewidth=2,
                           color='#1976D2',
                           linestyle='--')
ax.add_patch(api_conn1)

api_conn2 = FancyArrowPatch((15.25, 9), (11.75, 6),
                           connectionstyle="arc3,rad=-0.3",
                           arrowstyle='->',
                           mutation_scale=15,
                           linewidth=2,
                           color='#7B1FA2',
                           linestyle='--')
ax.add_patch(api_conn2)

# Cloud IAP
iap_box = FancyBboxPatch((0.5, 2), 4, 1.5,
                        boxstyle="round,pad=0.05",
                        facecolor='#E8EAF6',
                        edgecolor='#3F51B5',
                        linewidth=2)
ax.add_patch(iap_box)
ax.text(2.5, 3, 'Cloud IAP', fontsize=10, fontweight='bold', ha='center')
ax.text(2.5, 2.7, 'SSH Access', fontsize=8, ha='center')
ax.text(2.5, 2.4, '35.235.240.0/20', fontsize=8, ha='center')
ax.text(2.5, 2.2, 'No External IP needed', fontsize=8, ha='center', style='italic')

# IAP connection
iap_conn = FancyArrowPatch((2.5, 3.5), (3.25, 9.3),
                          connectionstyle="arc3,rad=0.3",
                          arrowstyle='->',
                          mutation_scale=15,
                          linewidth=2,
                          color='#3F51B5',
                          linestyle=':')
ax.add_patch(iap_conn)

# Firewall Rules section
firewall_box = FancyBboxPatch((15.5, 2), 4, 1.5,
                             boxstyle="round,pad=0.05",
                             facecolor='#FFEBEE',
                             edgecolor='#D32F2F',
                             linewidth=2)
ax.add_patch(firewall_box)
ax.text(17.5, 3, 'Firewall Rules', fontsize=10, fontweight='bold', ha='center')
ax.text(17.5, 2.7, '✓ VPN Traffic', fontsize=8, ha='center')
ax.text(17.5, 2.4, '✓ Internal Communication', fontsize=8, ha='center')
ax.text(17.5, 2.2, '✗ SSH Denied (Prod)', fontsize=8, ha='center', color='red')

# Service Accounts
sa_box = FancyBboxPatch((8, 2), 4, 1.5,
                       boxstyle="round,pad=0.05",
                       facecolor='#E8F5E9',
                       edgecolor='#388E3C',
                       linewidth=2)
ax.add_patch(sa_box)
ax.text(10, 3, 'Service Accounts', fontsize=10, fontweight='bold', ha='center')
ax.text(10, 2.7, 'dev-vm-sa', fontsize=8, ha='center')
ax.text(10, 2.4, 'roles/aiplatform.user', fontsize=8, ha='center')
ax.text(10, 2.2, 'Cross-project access', fontsize=8, ha='center', style='italic')

# Legend
legend_elements = [
    mlines.Line2D([0], [0], color=dev_color, lw=3, label='Dev Environment'),
    mlines.Line2D([0], [0], color=prod_color, lw=3, label='Prod Environment'),
    mlines.Line2D([0], [0], color=vpn_color, lw=3, label='VPN Connection'),
    mlines.Line2D([0], [0], color='#1976D2', lw=2, linestyle='--', label='API Access'),
    mlines.Line2D([0], [0], color='#3F51B5', lw=2, linestyle=':', label='IAP SSH Access')
]
ax.legend(handles=legend_elements, loc='lower center', ncol=5, 
         bbox_to_anchor=(0.5, -0.05), frameon=True, fancybox=True)

# Key Features box
features_box = FancyBboxPatch((0.5, 0.2), 19, 1.2,
                             boxstyle="round,pad=0.05",
                             facecolor='#F5F5F5',
                             edgecolor='#757575',
                             linewidth=1)
ax.add_patch(features_box)
ax.text(10, 1.1, 'Key Features:', fontsize=10, fontweight='bold', ha='center')
ax.text(10, 0.8, '• HA VPN with dual tunnels for redundancy  • BGP routing for dynamic route exchange  • Private Google Access for secure API calls', 
        fontsize=9, ha='center')
ax.text(10, 0.5, '• Cloud NAT for outbound internet access  • Cloud IAP for secure SSH without external IPs  • Cross-project IAM for Gemini API access', 
        fontsize=9, ha='center')

plt.tight_layout()
plt.savefig('gcp-hybrid-network-architecture.png', dpi=300, bbox_inches='tight', 
            facecolor='white', edgecolor='none')
plt.savefig('gcp-hybrid-network-architecture.pdf', bbox_inches='tight', 
            facecolor='white', edgecolor='none')
plt.show()