#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Pterodactyl Docker Setup Script${NC}"
echo "This script will help you set up your environment files and generate secure passwords."

# Function to generate a secure password
generate_password() {
    openssl rand -base64 32
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run as root${NC}"
    exit 1
fi

# Make sure we're in the right directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "\n${GREEN}Setting up Panel Environment${NC}"
if [ -d "panel/compose" ]; then
    # Backup existing .env if it exists
    if [ -f "panel/compose/.env" ]; then
        echo -e "${YELLOW}Backing up existing panel .env file...${NC}"
        cp panel/compose/.env "panel/compose/.env.backup-$(date +%Y%m%d-%H%M%S)"
    fi

    # Create new .env from template
    cp panel/compose/.env.template panel/compose/.env
    chmod 600 panel/compose/.env

    # Generate passwords
    DB_PASSWORD=$(generate_password)
    DB_ROOT_PASSWORD=$(generate_password)
    HASHIDS_SALT=$(generate_password)
    APP_KEY="base64:$(generate_password)"

    # Get domain
    echo -e "${YELLOW}Enter your panel domain (without https://)${NC}"
    echo -e "Example: panel.yourdomain.com"
    read -p "> " PANEL_DOMAIN
    PANEL_DOMAIN=${PANEL_DOMAIN:-panel.example.com}

    # Save generated passwords
    echo -e "\n${GREEN}Saving panel configuration...${NC}"
    echo "# Generated on $(date)" >> panel/compose/.env
    echo "DB_PASSWORD=$DB_PASSWORD" >> panel/compose/.env
    echo "DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD" >> panel/compose/.env
    echo "HASHIDS_SALT=$HASHIDS_SALT" >> panel/compose/.env
    echo "APP_KEY=$APP_KEY" >> panel/compose/.env
    echo "PANEL_DOMAIN=$PANEL_DOMAIN" >> panel/compose/.env
    echo "APP_URL=https://$PANEL_DOMAIN" >> panel/compose/.env

    echo -e "${GREEN}Panel environment file created with secure passwords${NC}"
    echo -e "${YELLOW}Please save these passwords in a secure location:${NC}"
    echo "Database Password: $DB_PASSWORD"
    echo "Database Root Password: $DB_ROOT_PASSWORD"
fi

echo -e "\n${GREEN}Setting up Wings Environment${NC}"
if [ -d "wings/compose" ]; then
    # Backup existing .env if it exists
    if [ -f "wings/compose/.env" ]; then
        echo -e "${YELLOW}Backing up existing wings .env file...${NC}"
        cp wings/compose/.env "wings/compose/.env.backup-$(date +%Y%m%d-%H%M%S)"
    fi

    # Create new .env from template
    cp wings/compose/.env.template wings/compose/.env
    chmod 600 wings/compose/.env

    # Get domain
    echo -e "${YELLOW}Enter your wings domain (without https://)${NC}"
    echo -e "Example: wings.yourdomain.com"
    read -p "> " WINGS_DOMAIN
    WINGS_DOMAIN=${WINGS_DOMAIN:-wings.example.com}

    # Update wings domain in .env
    echo "WINGS_DOMAIN=$WINGS_DOMAIN" >> wings/compose/.env
    echo -e "${GREEN}Wings environment file created${NC}"
fi

# Set Traefik permissions
if [ -f "_base/data/traefik/acme.json" ]; then
    echo -e "\n${GREEN}Setting up Traefik SSL storage${NC}"
    chmod 600 _base/data/traefik/acme.json
fi

echo -e "\n${GREEN}Setup Complete!${NC}"
echo -e "\nNext steps:"
echo -e "1. ${YELLOW}For Panel Server:${NC}"
echo -e "   - cd panel/compose"
echo -e "   - docker-compose up -d"
echo -e "   - docker-compose run --rm panel php artisan p:user:make"
echo -e "\n2. ${YELLOW}For Wings Server:${NC}"
echo -e "   - Create the pterodactyl network: docker network create pterodactyl"
echo -e "   - cd wings/compose"
echo -e "   - docker-compose up -d"
echo -e "\n${YELLOW}Remember to store your passwords in a secure password manager!${NC}" 