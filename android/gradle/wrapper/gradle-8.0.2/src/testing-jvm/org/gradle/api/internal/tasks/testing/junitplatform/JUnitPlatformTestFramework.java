/*
 * Copyright 2018 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.gradle.api.internal.tasks.testing.junitplatform;

import com.google.common.collect.ImmutableList;
import org.gradle.api.Action;
import org.gradle.api.JavaVersion;
import org.gradle.api.internal.tasks.testing.TestFramework;
import org.gradle.api.internal.tasks.testing.WorkerTestClassProcessorFactory;
import org.gradle.api.internal.tasks.testing.detection.TestFrameworkDetector;
import org.gradle.api.internal.tasks.testing.filter.DefaultTestFilter;
import org.gradle.api.tasks.testing.TestFilter;
import org.gradle.api.tasks.testing.junitplatform.JUnitPlatformOptions;
import org.gradle.internal.jvm.UnsupportedJavaRuntimeException;
import org.gradle.internal.scan.UsedByScanPlugin;
import org.gradle.process.internal.worker.WorkerProcessBuilder;

import java.io.IOException;
import java.util.List;

@UsedByScanPlugin("test-retry")
public class JUnitPlatformTestFramework implements TestFramework {
    private final JUnitPlatformOptions options;
    private final DefaultTestFilter filter;
    private final boolean useImplementationDependencies;

    public JUnitPlatformTestFramework(DefaultTestFilter filter, boolean useImplementationDependencies) {
        this(filter, useImplementationDependencies, new JUnitPlatformOptions());
    }

    private JUnitPlatformTestFramework(DefaultTestFilter filter, boolean useImplementationDependencies, JUnitPlatformOptions options) {
        this.filter = filter;
        this.useImplementationDependencies = useImplementationDependencies;
        this.options = options;
    }

    @UsedByScanPlugin("test-retry")
    @Override
    public TestFramework copyWithFilters(TestFilter newTestFilters) {
        JUnitPlatformOptions copiedOptions = new JUnitPlatformOptions();
        copiedOptions.copyFrom(options);

        return new JUnitPlatformTestFramework(
            (DefaultTestFilter) newTestFilters,
            useImplementationDependencies,
            copiedOptions
        );
    }

    @Override
    public WorkerTestClassProcessorFactory getProcessorFactory() {
        if (!JavaVersion.current().isJava8Compatible()) {
            throw new UnsupportedJavaRuntimeException("Running JUnit Platform requires Java 8+, please configure your test java executable with Java 8 or higher.");
        }
        return new JUnitPlatformTestClassProcessorFactory(new JUnitPlatformSpec(
            filter.toSpec(), options.getIncludeEngines(), options.getExcludeEngines(),
            options.getIncludeTags(), options.getExcludeTags()
        ));
    }

    @Override
    public Action<WorkerProcessBuilder> getWorkerConfigurationAction() {
        return workerProcessBuilder -> workerProcessBuilder.sharedPackages("org.junit");
    }

    @Override
    public List<String> getWorkerApplicationModulepathModuleNames() {
        return ImmutableList.of("junit-platform-engine", "junit-platform-launcher", "junit-platform-commons");
    }

    @Override
    public boolean getUseDistributionDependencies() {
        return useImplementationDependencies;
    }

    @Override
    public JUnitPlatformOptions getOptions() {
        return options;
    }

    @Override
    public TestFrameworkDetector getDetector() {
        return null;
    }

    @Override
    public void close() throws IOException {
        // this test framework doesn't hold any state
    }

}
