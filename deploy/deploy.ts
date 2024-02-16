import { Address, Deployer } from "../web3webdeploy/types";

export interface DeploymentSettings {}

export interface Deployment {}

export async function deploy(
  deployer: Deployer,
  settings?: DeploymentSettings
): Promise<Deployment> {
  return {};
}
