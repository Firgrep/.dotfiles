# Wrong sound profiles/codecs for bluetooth headset

Fix:

- `sudo nano /etc/bluetooth/main.conf`
- add lines

  ```sh
    # Automatically connect both A2DP and HFP/HSP profiles for incoming
    # connections. Some headsets that support both profiles will only connect the
    # other one automatically so the default setting of true is usually a good
    # idea.
    AutoConnect=true

    # find and uncomment:
    MultiProfile = multiple

  ```

- `sudo systemctl restart bluetooth`
