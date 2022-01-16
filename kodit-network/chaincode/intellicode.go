
package main

import (
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type MyChaincode struct {
}

func (t *MyChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("Init")
        return shim.Success(nil)
}

func (t *MyChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("Invoke")
	function, args := stub.GetFunctionAndParameters()

	if function == "insert" {
		return t.insert(stub, args)
	} else if function == "delete" {
		return t.delete(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	}

	return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"insert\" \"delete\" \"query\"")
}


func (t *MyChaincode) insert(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var XX string		// Entities
	var err error

        if len(args) != 2 {
                return shim.Error("Incorrect number of arguments. Expecting 2")
        }

        XX = args[0]

        err = stub.PutState( XX, []byte(args[1]) )
        if err != nil {
                return shim.Error(err.Error())
        }
        return shim.Success(nil)
}


// query callback representing the query of a chaincode
func (t *MyChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
        var A string
        var err error

        if len(args) != 1 {
                return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
        }

        A = args[0]
        // Get the state from the ledger
        Avalbytes, err := stub.GetState(A)
        if err != nil {
                jsonResp := "{\"Error\":\"Failed to get state for " + A + "\"}"
                return shim.Error(jsonResp)
        }

        if Avalbytes == nil {
                jsonResp := "{\"Error\":\"Nil amount for " + A + "\"}"
                return shim.Error(jsonResp)
        }

        jsonResp := "{\"Name\":\"" + A + "\",\"Amount\":\"" + string(Avalbytes) + "\"}"
        fmt.Printf("Query Response:%s\n", jsonResp)
        return shim.Success( Avalbytes )  	// byte[](Avalbytes)
}


// Deletes an entity from state
func (t *MyChaincode) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
        var B string
        var err error

        if len(args) != 1 {
                return shim.Error("Incorrect number of arguments. Expecting 1")
        }
        B = args[0]

        // Delete the key from the state in ledger
        err = stub.DelState(B)
        if err != nil {
                return shim.Error("Failed to delete state")
        }
        return shim.Success(nil)
}


func main() {
	err := shim.Start( new(MyChaincode) )
	if err != nil {
		fmt.Printf("Error starting My chaincode: %s", err)
	}
}
