#!/usr/bin/env python3
"""
ConnectAssist VPS Deployment Script
Triggers deployment via API endpoint
"""

import requests
import json
import sys

def deploy_to_vps():
    """Deploy updates to VPS via API endpoint"""
    
    print("🚀 ConnectAssist VPS Deployment")
    print("=" * 50)
    
    # API endpoint
    deploy_url = "https://connectassist.live/api/deploy"
    
    # Deployment payload
    payload = {
        "deploy_key": "ConnectAssist2024Deploy"
    }
    
    try:
        print("📡 Triggering deployment via API...")
        
        # Send deployment request
        response = requests.post(
            deploy_url,
            json=payload,
            headers={'Content-Type': 'application/json'},
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print("✅ Deployment successful!")
                print(f"📝 Git output: {result.get('git_output', 'No output')}")
                print("\n🔄 Services are restarting...")
                print("🌐 Check https://connectassist.live in a few moments")
                return True
            else:
                print(f"❌ Deployment failed: {result.get('error')}")
                return False
        else:
            print(f"❌ HTTP Error {response.status_code}: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Connection error: {e}")
        print("\n🔧 Troubleshooting:")
        print("1. Check if the VPS is accessible: https://connectassist.live")
        print("2. Verify the API endpoint is running")
        print("3. Check network connectivity")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def test_api_endpoints():
    """Test the new API endpoints"""
    
    print("\n🧪 Testing API Endpoints")
    print("=" * 30)
    
    endpoints = [
        ("System Status", "https://connectassist.live/api/status"),
        ("Admin Dashboard", "https://connectassist.live/admin/"),
        ("Customer Portal", "https://connectassist.live/")
    ]
    
    for name, url in endpoints:
        try:
            print(f"Testing {name}...")
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                print(f"✅ {name}: OK")
            else:
                print(f"⚠️ {name}: HTTP {response.status_code}")
        except Exception as e:
            print(f"❌ {name}: {e}")

def main():
    """Main deployment function"""
    
    print("ConnectAssist Customer Portal Integration Deployment")
    print("=" * 60)
    
    # Step 1: Deploy updates
    print("\n📦 Step 1: Deploying updates to VPS...")
    if not deploy_to_vps():
        print("\n❌ Deployment failed. Please check the errors above.")
        sys.exit(1)
    
    # Step 2: Wait for services to restart
    print("\n⏳ Step 2: Waiting for services to restart...")
    import time
    time.sleep(10)
    
    # Step 3: Test endpoints
    print("\n🧪 Step 3: Testing API endpoints...")
    test_api_endpoints()
    
    print("\n" + "=" * 60)
    print("🎉 Deployment Complete!")
    print("\n📋 Next Steps:")
    print("1. Visit https://connectassist.live/admin/ for the admin dashboard")
    print("2. Visit https://connectassist.live/ for the customer portal")
    print("3. Test the complete workflow:")
    print("   - Generate support code in admin dashboard")
    print("   - Enter code in customer portal")
    print("   - Download and test installer")
    print("\n🔗 Quick Links:")
    print("- Admin Dashboard: https://connectassist.live/admin/")
    print("- Customer Portal: https://connectassist.live/")
    print("- API Status: https://connectassist.live/api/status")

if __name__ == "__main__":
    main()
