# orloj
The orloj package includes a set of utilities for importing data from and interacting with the Astrolabe platform. As an Astrolabe user, you are welcome to download this data through the experiment Export button, which will download the `experiment.zip` file. For further description of the export file and the specifics of the Astrolabe pipeline, [refer to the introduction](introduction.md).

## Installation
You can install orloj through the R command line. Please make sure to run R in administrator or sudo mode, then execute the following:

1. Install the required Bioconductor packages:
```
install.packages("BiocManager")
BiocManager::install("flowCore")
BiocManager::install("FlowSOM")
BiocManager::install("edgeR")
```

2. Install devtools and patchwork:
```
install.packages("devtools")
install.packages("patchwork")
```

3. Install orloj from the github repository:
```
devtools::install_github("astrolabediagnostics/orloj")
```

## Operation

orloj provides access to the RDS files that are exported by Astrolabe. Before proceeding, please read the [introduction](introduction.md) to the various analyses and reports generated by Astrolabe.

> Throughout this guide technical notes appear in blockquote.
>
> The examples here use data from [Tordesillas et al., J Allergy Clin Immunol, 2016](https://www.ncbi.nlm.nih.gov/pubmed/27531074). You can download the raw data from [the FlowRepository repo](https://flowrepository.org/id/FR-FCM-ZZTW), or download the [Astrolabe `analysis.zip` file](https://s3.us-east-2.amazonaws.com/astrolabediagnostics-public/astrolabe_analysis_tordesillas_et_al.zip). We assume that you unzipped the file to `D:/data/tordesillas`.

All orloj operations are done within the scope of an Astrolabe experiment. Start by loading the experiment:

```
> experiment <- orloj::loadExperiment([experiment_path])
```

To load the data used in this experiment, substitute `[experiment_path]` to the directory where you unzipped `experiment.zip`:

```
> experiment <- orloj::loadExperiment("D:/data/tordesillas")
```

> The experiment directory will have the `config.RDS` file. This file includes the sample and feature information that was entered during Astrolabe experiment setup.

Use `orloj::experimentSummary` to get a brief summary of the experiment contents:

```
> orloj::experimentSummary(experiment)
Astrolabe experiment with 54 samples and 31 channels

Classification channels: CD66b, CD19, CD45RA, CD141, CD4, CD8a, CD20, CD16, CD66a, CD61, CD123, CD23, CD27, CD11c, CD14, CD32, CD63, CD3, CD38, CD56, HLADR

Sample features:
patient: c1, c2, c3, p1, p2, p3, p4, p5, p6
type: healthy, peanut allergic
condition: anti ige, media, peanut extract
timepoint: 15m, 30m
```

### Sample Data

`experiment` is an R list which contains the parameters you supplied when setting up the experiment, in addition to various parameters created by Astrolabe. For example, you can access the experiment samples list using `experiment$samples`:

```
> print(experiment$samples)
# A tibble: 54 x 3
   SampleId             Name             Filename
      <chr>            <chr>                <chr>
 1        1 C1 15min antiIgE C1_15min_antiIgE.fcs
 2        2   C2 15min media   C2_15min_media.fcs
 3        3 C1 30min antiIgE C1_30min_antiIgE.fcs
 4        4      C1 30min PN      C1_30min_PN.fcs
 5        5   C1 30min media   C1_30min_media.fcs
 6        6      C1 15min PN      C1_15min_PN.fcs
 7        7 C2 30min antiIgE C2_30min_antiIgE.fcs
 8        8 C2 15min antiIgE C2_antiIgE_15min.fcs
 9        9      C2 15min PN      C2_15min_PN.fcs
10       10      C2 30min PN      C2_30min_PN.fcs
# ... with 44 more rows
```

The `SampleId` is an internal Astrolabe field -- you will notice that the `/analysis/` directory has several files of the format `[sample_id].[analysis_name].RDS`. Fortunately, you do not need to interact with these files directly. For a given sample, you can load all of the analyses for that sample:

```
> sample <- orloj::loadSample(experiment, sample_name = "C1 15min antiIgE")
> orloj::sampleSummary(sample)
An Astrolabe sample with 115242 cells and 49 channels
2661 bead events and 346946 debris events
```

> If you would like to load samples using Astrolabe sample IDs, use `orloj::loadSampleData(experiment, sample_id = 1)`.

After loading a sample, you can access its FCS data and cell subset assignments:

```
> exprs <- orloj::fcsExprs(sample)
> dim(exprs)
[1] 115242     54
> colnames(exprs)
 [1] "Time"         "Event_length" "Pd102Di"      "Pd104Di"      "Pd105Di"      "Pd106Di"     
 [7] "Pd108Di"      "Pd110Di"      "CD66b"        "HLA_ABC"      "Xe131Di"      "Cs133Di"     
[13] "Ce140Di"      "Pr141Di"      "CD19"         "Ce142Di"      "CD45RA"       "CD141"       
[19] "CD4"          "CD8a"         "CD20"         "CD16"         "CD66a"        "CD61"        
[25] "CD123"        "Sm152Di"      "CD23"         "CD45"         "CD27"         "p38"         
[31] "CD11c"        "CD14"         "CD32"         "CRTH2"        "IkBa"         "FceRIa"      
[37] "CD63"         "Er167Di"      "Tm169Di"      "CD3"          "pERK"         "CD38"        
[43] "CD56"         "HLADR"        "pS6"          "Lu176Di"      "Os189Di"      "Ir191Di_DNA" 
[49] "Ir193Di_DNA"  "Assignment"   "Level_0"      "Level_1"      "Level_2"      "Profiling"     
```

`exprs` is a data frame with a row for each cell. It includes the original FCS data after transformation. Additionally, it has additional columns for Astrolabe's automatic cell subset classifier (gating). `Assignment` and `Profiling` correspond to the terminal labels For each cell. The `Level_i` columns correspond to intermediate steps in the hierarchy -- we recommend against using them, unless you would like to focus on a specific subset.

> Astrolabe uses hyperbolic arcsine with a cofactor of 5 when transforming mass cytometry data.
>
> By default, `orloj::fcsExprs` removes events that were identified as debris by Astrolabe. If you would like to keep them, call `orloj::fcsExprs(s, keep_debris = TRUE)` instead. `orloj::fcsExprs` always removes events that were identified as CyTOF calibration beads.

orloj supplies two functions for easily accessing the sample's subet cell counts and channel intensity medians:

```
> sampleCellSubsetCounts(sample)
# A tibble: 12 x 2
                           CellSubset     N
                                <chr> <int>
 1                           Basophil  2219
 2                             B Cell   211
 3 CD141+ Conventional Dendritic Cell   714
 4                     CD14+ Monocyte 20945
 5                     CD16+ Monocyte   652
 6                      CD16- NK Cell   612
 7                        CD4+ T Cell 37815
 8                        CD8+ T Cell 21437
 9                        Granulocyte 16924
10                 Myeloid_unassigned  4502
11                    Root_unassigned  3297
12                  T Cell_unassigned  5914
>
> sampleCellSubsetChannelStatistics(sample) %>% dplyr::arrange(CellSubset)
# A tibble: 336 x 5
   CellSubset ChannelName      Mean        Sd    Median
        <chr>       <chr>     <dbl>     <dbl>     <dbl>
 1   Basophil       CD66b 1.0648623 0.8579865 0.9551815
 2   Basophil     HLA_ABC 3.5587049 0.6760540 3.5720787
 3   Basophil        CD19 0.3356665 0.5086242 0.0000000
 4   Basophil      CD45RA 0.6741676 0.6827153 0.5181072
 5   Basophil       CD141 0.3759006 0.5336876 0.0181990
 6   Basophil         CD4 0.1399595 0.3510070 0.0000000
 7   Basophil        CD8a 0.2580162 0.4292534 0.0000000
 8   Basophil        CD20 0.5901105 0.5963551 0.4241660
 9   Basophil        CD16 1.3112481 1.1552829 1.0417074
10   Basophil       CD66a 2.5811629 1.6747920 2.2227098
# ... with 326 more rows
```

### Experiment Analyses

The subset cell counts over all samples can be accessed using `orloj::experimentCellSubsetCounts`:

```
> experimentCellSubsetCounts(experiment) %>% dplyr::arrange(CellSubset)
# A tibble: 689 x 5
   SampleId             Name             Filename CellSubset     N
      <chr>            <chr>                <chr>      <chr> <int>
 1        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil  2219
 2        2   C2 15min media   C2_15min_media.fcs   Basophil  2916
 3        3 C1 30min antiIgE C1_30min_antiIgE.fcs   Basophil  2321
 4        4      C1 30min PN      C1_30min_PN.fcs   Basophil  1943
 5        5   C1 30min media   C1_30min_media.fcs   Basophil  2565
 6        6      C1 15min PN      C1_15min_PN.fcs   Basophil  2438
 7        7 C2 30min antiIgE C2_30min_antiIgE.fcs   Basophil  3382
 8        8 C2 15min antiIgE C2_antiIgE_15min.fcs   Basophil  4949
 9        9      C2 15min PN      C2_15min_PN.fcs   Basophil  3036
10       10      C2 30min PN      C2_30min_PN.fcs   Basophil  2881
# ... with 679 more rows
```

And similarly for subset channel intensity statistics:

```
> experimentCellSubsetChannelStatistics(experiment) %>% dplyr::arrange(CellSubset)
# A tibble: 19,292 x 8
   SampleId             Name             Filename CellSubset ChannelName      Mean        Sd    Median
      <chr>            <chr>                <chr>      <chr>       <chr>     <dbl>     <dbl>     <dbl>
 1        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil       CD66b 1.0648623 0.8579865 0.9551815
 2        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil     HLA_ABC 3.5587049 0.6760540 3.5720787
 3        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil        CD19 0.3356665 0.5086242 0.0000000
 4        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil      CD45RA 0.6741676 0.6827153 0.5181072
 5        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil       CD141 0.3759006 0.5336876 0.0181990
 6        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil         CD4 0.1399595 0.3510070 0.0000000
 7        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil        CD8a 0.2580162 0.4292534 0.0000000
 8        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil        CD20 0.5901105 0.5963551 0.4241660
 9        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil        CD16 1.3112481 1.1552829 1.0417074
10        1 C1 15min antiIgE C1_15min_antiIgE.fcs   Basophil       CD66a 2.5811629 1.6747920 2.2227098
# ... with 19,282 more rows
```

> Remember that you can always supply `level = "Profiling"` as a function parameter to access the `Profiling` level instead of the default `Assignment` level.

Finally, you can access the differential abundance analysis results:

```
> daa <- orloj::differentialAbundanceAnalysis(experiment)
> names(daa)
[1] "patient"   "type"      "condition" "timepoint"
```

Astrolabe runs the analysis for each of the features you supplied during experiment setup. Each of these include the P-values, FDR, and feature value medians for each cell subset:

```
> daa$condition
> daa$condition
                           CellSubset    PValue       FDR median_anti ige median_media median_peanut extract
1                   T Cell_unassigned 0.1248214 0.9058288    0.0506369973 0.0493739530          4.847519e-02
2                     Root_unassigned 0.2907044 0.9058288    0.0056848426 0.0056272949          5.843414e-03
3                         Granulocyte 0.4423689 0.9058288    0.1092210834 0.0830771861          1.365757e-01
4         Plasmacytoid Dendritic Cell 0.4483833 0.9058288    0.0048429066 0.0042607659          4.857075e-03
5                         CD4+ T Cell 0.5454668 0.9058288    0.2989413963 0.3207483271          3.111650e-01
6                         CD8+ T Cell 0.5575078 0.9058288    0.1819280851 0.1982661806          1.906808e-01
7                              B Cell 0.6167987 0.9058288    0.0448034615 0.0340524660          4.073054e-02
8                      CD16+ Monocyte 0.7515697 0.9058288    0.0106419480 0.0108713938          1.169913e-02
9                      CD14+ Monocyte 0.7838902 0.9058288    0.1333721631 0.1580286985          1.458530e-01
10                           Basophil 0.7944606 0.9058288    0.0233674522 0.0246680809          2.144130e-02
11                      CD16- NK Cell 0.7958336 0.9058288    0.0069009109 0.0055712110          6.395491e-03
12                 Myeloid_unassigned 0.8383330 0.9058288    0.0498024335 0.0457445240          4.446624e-02
13                      CD16+ NK Cell 0.8411267 0.9058288    0.0002580689 0.0003215008          8.402538e-05
14 CD141+ Conventional Dendritic Cell 0.9503421 0.9503421    0.0020229537 0.0018712104          2.828895e-03
```
