# LIGO Vesting (cameligo)

## Introduction

The Vesting contract can be used task related to fund distribution (ICO, corporate actions).
Ce projet contient un contrat de Vesting (tokens verrouillés) ainsi que ses tests.

## Auteurs
- Dorian Moulin

## Makefile

If you have cloned this repo, you can use the makefile to easily compile contract with `make compile` or run tests `make test` or run tests on a single exercice `make test SUITE=exo_1_solution`

## Compilation
Pour compiler ce projet, vous aurez besoin d'utiliser le compilateur Ligo. La compilation transforme le code source de votre contrat en un format que la blockchain peut exécuter. Suivez les étapes ci-dessous pour compiler le projet :

```bash
make compile
```

## Déploiement

Pour déployer le contrat sur la blockchain, suivez les étapes ci-dessous. Assurez-vous que toutes les configurations préalables sont correctement établies et que vous avez compilé le contrat comme indiqué dans la section précédente.

1. **Préparation :** Avant de procéder au déploiement, vérifiez que vous avez bien défini toutes les variables d'environnement nécessaires, y compris `PRIVATE_KEY` et `PUBLIC_KEY`. Ces clés sont cruciales pour l'authentification et la sécurisation de votre déploiement.

2. **Lancement du déploiement :** Pour déployer votre contrat de vesting, exécutez la commande suivante dans votre terminal :

```bash
make deploy
```


```
src/Vesting.mligo
```

## Exercices

Create a smart contract (called Vesting) that distributes funds to beneficiaries on a period of time.
Funds are implemented as a FA2 token (TZIP-12).
Funds are first frozen during a freeze period (i.e. funds cannot be claimed). Then funds are available (i.e.
claimable) on time basis. During the vesting period, funds are claimable proportionnaly to the vesting period
duration. At the end of the vesting period, 100% of funds are claimable.
The administrator of the Vesting contract is the user who deployed the Vesting contract.
The administrator can call the `Start` entrypoint which will trigger the beginning of the freeze period and the
lock of funds (i.e. fund transfer from administrator to the Vesting contract) . Once the Vesting contract is
started, the beneficiaries cannot be changed, and vesting start time and end time cannot be changed.
The beneficiaries are specified at the creation of the contract, with their corresponding promised amounts of
token.
An entrypoint `UpdateBeneficiary` must be provided to modify the beneficiaries. This entrypoint must be
callable only by the administrator if the Vesting contract is not started yet.
The vesting duration, and freeze period duration are specified at the creation of the contract.
The FA2 token (address and token_id) that is used to represent funds must be specified at the creation of
the contract.
Available funds can be claimed by a beneficiary. The `claim` entrypoint transfers available amount of tokens
(and which has not been claimed yet) to the beneficiary.
A `kill` entrypoint callable only by the administrator must be implemented to be able to retrieve funds, and
pay beneficiaries (on time elpased basis) and to clean the storage. 
