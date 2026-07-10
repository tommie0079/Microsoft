Quick ref dynamic groups

# Microsoft Entra ID Dynamic Group Rules

## Group for Windows Devices

**Rule**

```text
(device.deviceOSType -eq "Windows")
```

---

## Group for Autopilot Devices

**Rule**

```text
(device.devicePhysicalIDs -any (_ -startsWith "[ZTDid]"))
```

**Description**

Includes all Windows Autopilot registered devices.

---

## Group for Android Devices

**Rule**

```text
(device.deviceOSType -eq "Android")
```

---

## Group for Entra-Group-Example

**Rule**

```text
(user.department -eq "Example")
```

---

## Group for All Users

**Rule**

```text
(user.accountEnabled -eq true)
```

---

# Additional Useful Dynamic Groups

## All iOS Devices

```text
(device.deviceOSType -eq "iPhone")
```

---

## All macOS Devices

```text
(device.deviceOSType -eq "MacMDM")
```

---

## All Linux Devices

```text
(device.deviceOSType -eq "Linux")
```

---

## All Enabled Guest Users

```text
(user.userType -eq "Guest") and (user.accountEnabled -eq true)
```

---

## All Licensed Users

```text
(user.assignedPlans -any (assignedPlan.capabilityStatus -eq "Enabled"))
```

---

## Users with Business Premium Licenses

```text
(user.assignedPlans -any (assignedPlan.servicePlanId -eq "<ServicePlanID>"))
```

> Replace `<ServicePlanID>` with the appropriate Microsoft 365 service plan ID.

---

## Users in IT Department

```text
(user.department -eq "IT")
```

---

## Users in Norway

```text
(user.country -eq "Norway")
```

---

## Windows 11 Devices

```text
(device.deviceOSType -eq "Windows") and (device.deviceOSVersion -startsWith "10.0.22")
```

> Windows 11 builds typically start with 10.0.22000, 22621, 22631, etc.

---

## Autopilot Devices with Group Tag

```text
(device.devicePhysicalIds -any (_ -eq "[OrderID]:Production"))
```

### Example Group Tags

```text
[OrderID]:Production
[OrderID]:Test
[OrderID]:Kiosk
```

These are extremely useful for assigning different Autopilot profiles, applications, compliance policies, and update rings.

---

# Recommended Groups for a Small Intune Environment

### Users

- All Users
- IT Department
- Test Users
- Guest Users

### Devices

- Autopilot Devices
- Windows Devices
- Android Devices
- iOS Devices
- Test Devices (Group Tag: Test)
- Production Devices (Group Tag: Production)

### Administration

- Break Glass Accounts (Assigned membership)
- Intune Administrators (Assigned membership)
- Global Administrators (Assigned membership)

> Administrative groups should generally use **Assigned** membership instead of Dynamic membership.
