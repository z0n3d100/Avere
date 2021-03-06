// Copyright (C) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See LICENSE-CODE in the project root for license information.
package cachewarmer

import (
	"encoding/json"
	"fmt"
	"hash/fnv"
	"io"
	"io/ioutil"
	"os"
	"path"
	"time"

	"github.com/Azure/Avere/src/go/pkg/log"
)

// WorkerJob contains the information for a worker job item
type WorkerJob struct {
	WarmTargetMountAddresses []string
	WarmTargetExportPath     string
	WarmTargetPath           string
	StartByte                int64
	StopByte                 int64
}

func JobsExist(jobFolder string) (exists bool, mountCount int, err error) {
	log.Debug.Printf("[JobsExist %s", jobFolder)
	log.Debug.Printf("JobsExist %s]", jobFolder)
	f, err := os.Open(jobFolder)
	if err != nil {
		return exists, mountCount, fmt.Errorf("error reading files from directory '%s': '%v'\n", jobFolder, err)
	}
	defer f.Close()

	for {
		files, err := f.Readdirnames(MinimumJobsOnDirRead)
		if len(files) == 0 && err == io.EOF {
			return false, mountCount, nil
		}
		if err != nil && err != io.EOF {
			return exists, mountCount, err
		}
		for _, filename := range files {
			fullpath := path.Join(jobFolder, filename)
			byteContent, err := ioutil.ReadFile(fullpath)
			if err != nil {
				log.Error.Printf("error readingfile '%s': %v", fullpath, err)
				continue
			}
			warmPathJob, err := InitializeWorkerJobFromString(string(byteContent))
			if err != nil {
				log.Error.Printf("error serializing file '%s': %v", fullpath, err)
				if e2 := os.Remove(fullpath); e2 != nil {
					log.Error.Printf("error removing '%s': %v", fullpath, e2)
				}
				continue
			}
			return true, len(warmPathJob.WarmTargetMountAddresses), nil
		}
	}
}

// InitializeWorkerJob initializes the worker job structure
func InitializeWorkerJob(
	warmTargetMountAddresses []string,
	warmTargetExportPath string,
	warmTargetPath string,
	startByte int64,
	stopByte int64) *WorkerJob {
	return &WorkerJob{
		WarmTargetMountAddresses: warmTargetMountAddresses,
		WarmTargetExportPath:     warmTargetExportPath,
		WarmTargetPath:           warmTargetPath,
		StartByte:                startByte,
		StopByte:                 stopByte,
	}
}

// InitializeWorkerJobFromString reads warmPathJobContents
func InitializeWorkerJobFromString(workerJobContents string) (*WorkerJob, error) {
	var result WorkerJob
	if err := json.Unmarshal([]byte(workerJobContents), &result); err != nil {
		return nil, err
	}

	return &result, nil
}

// WriteJob outputs a JSON file
func (j *WorkerJob) WriteJob(jobpath string) error {
	// get the JSON output
	fileContents, err := j.GetWorkerJobFileContents()
	if err != nil {
		return err
	}

	workJobFilePath := GenerateWorkerJobFilename(jobpath, fileContents)

	// write the file
	log.Debug.Printf("write worker job file %s", workJobFilePath)
	if err := WriteFile(workJobFilePath, fileContents); err != nil {
		return err
	}

	return nil
}

// GetWorkerJobFileContents returns the contents of the file
func (j *WorkerJob) GetWorkerJobFileContents() (string, error) {
	data, err := json.Marshal(j)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// GenerateJobFilename generates a file name based on time, and the warm path
func GenerateWorkerJobFilename(jobpath string, contents string) string {
	// generate a hashcode of the string
	h := fnv.New32a()
	h.Write([]byte(contents))

	t := time.Now()
	return path.Join(jobpath, fmt.Sprintf("%02d-%02d-%02d-%02d%02d%02d.%d-%d.job", t.Year(), t.Month(), t.Day(), t.Hour(), t.Minute(), t.Second(), t.Nanosecond(), h.Sum32()))
}
