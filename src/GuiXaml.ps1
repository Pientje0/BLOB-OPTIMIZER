# ============================================================================
#  BLOB OPTIMIZER - GuiXaml.ps1
#  WPF markup for the window interface. WPF ships with Windows / .NET, so
#  nothing is downloaded or installed. Pure ASCII: glyphs use XML entities.
#
#  Design: an engineering spec sheet. Warm paper, near-black ink, one signal
#  colour (international orange) reserved for things that need attention.
#  Bahnschrift (built into Windows) for structure and numbers, Segoe UI for
#  reading, a monospace face only for technical values. Hairline rules
#  instead of boxes, almost no rounding, no shadows, no gradients.
# ============================================================================

$Blob.GuiTheme = @'
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
  <SolidColorBrush x:Key="Paper" Color="#EFECE6"/>
  <SolidColorBrush x:Key="Surface" Color="#F7F5F1"/>
  <SolidColorBrush x:Key="Ink" Color="#141414"/>
  <SolidColorBrush x:Key="Ink2" Color="#57544E"/>
  <SolidColorBrush x:Key="Ink3" Color="#8A867E"/>
  <SolidColorBrush x:Key="Rule" Color="#D6D2CA"/>
  <SolidColorBrush x:Key="Signal" Color="#FF4F00"/>
  <SolidColorBrush x:Key="SignalSoft" Color="#FBE4D7"/>
  <FontFamily x:Key="Display">Bahnschrift, Segoe UI</FontFamily>
  <FontFamily x:Key="Mono">Cascadia Mono, Consolas</FontFamily>

  <Style TargetType="TextBlock">
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="TextWrapping" Value="Wrap"/>
  </Style>

  <!-- Secondary button: hairline ink outline -->
  <Style TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderBrush" Value="{StaticResource Ink}"/>
    <Setter Property="Padding" Value="14,6"/>
    <Setter Property="Margin" Value="0,0,8,0"/>
    <Setter Property="FontFamily" Value="{StaticResource Display}"/>
    <Setter Property="FontSize" Value="13.5"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                  BorderThickness="1" CornerRadius="2" Padding="{TemplateBinding Padding}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#E4E0D8"/></Trigger>
            <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Background" Value="#D6D2CA"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.35"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <!-- Primary: solid ink -->
  <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
    <Setter Property="Background" Value="{StaticResource Ink}"/>
    <Setter Property="Foreground" Value="{StaticResource Paper}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                  BorderThickness="1" CornerRadius="2" Padding="{TemplateBinding Padding}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#333230"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.35"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
    <Setter Property="Foreground" Value="#B83A00"/>
    <Setter Property="BorderBrush" Value="#B83A00"/>
  </Style>
  <!-- Text-only button used for filters and links -->
  <Style x:Key="ChipButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Ink2}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="FontFamily" Value="{StaticResource Display}"/>
    <Setter Property="FontSize" Value="13.5"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Margin" Value="0,0,18,6"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="Transparent" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="0,0,0,2" Padding="0,2,0,3">
            <ContentPresenter VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter Property="Foreground" Value="{StaticResource Ink}"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <!-- Full-width list row used for "start here" actions -->
  <Style x:Key="RowButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{StaticResource Rule}" BorderThickness="0,0,0,1" Padding="2,13">
            <ContentPresenter HorizontalAlignment="Stretch"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#E8E4DC"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <!-- Table-of-contents navigation item; BorderBrush paints the marker bar -->
  <Style x:Key="NavButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Ink2}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="FontFamily" Value="{StaticResource Display}"/>
    <Setter Property="FontSize" Value="15"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Grid Background="Transparent">
            <Grid.ColumnDefinitions><ColumnDefinition Width="3"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border Grid.Column="0" Background="{TemplateBinding BorderBrush}"/>
            <Border x:Name="Bd" Grid.Column="1" Background="{TemplateBinding Background}" Padding="17,7,12,7">
              <ContentPresenter/>
            </Border>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#E4E0D8"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="TabButton" TargetType="Button" BasedOn="{StaticResource NavButton}"/>
  <Style x:Key="CaptionButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Width" Value="46"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#DEDAD2"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="CloseButton" TargetType="Button" BasedOn="{StaticResource CaptionButton}">
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#141414"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="IconButton" TargetType="Button" BasedOn="{StaticResource ChipButton}"/>

  <!-- On/off switch: rectangular, ink when on -->
  <Style x:Key="Switch" TargetType="CheckBox">
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Border x:Name="Track" Width="38" Height="20" Background="Transparent" BorderBrush="{StaticResource Ink}" BorderThickness="1.5" CornerRadius="2">
            <Border x:Name="Thumb" Width="14" Height="12" Background="{StaticResource Ink3}" HorizontalAlignment="Left" Margin="2,0" CornerRadius="1"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsChecked" Value="True">
              <Setter TargetName="Track" Property="Background" Value="{StaticResource Ink}"/>
              <Setter TargetName="Thumb" Property="Background" Value="{StaticResource Paper}"/>
              <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
            </Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Track" Property="Opacity" Value="0.3"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="CheckBox">
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Grid Background="Transparent">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border x:Name="Box" Width="16" Height="16" Background="Transparent" BorderBrush="{StaticResource Ink}"
                    BorderThickness="1.5" VerticalAlignment="Top" Margin="0,2,10,0">
              <Path x:Name="Mark" Data="M2.5,7.5 L6,11 L12.5,3.5" Stroke="{StaticResource Paper}" StrokeThickness="2" Visibility="Collapsed"/>
            </Border>
            <ContentPresenter Grid.Column="1" VerticalAlignment="Top"/>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsChecked" Value="True">
              <Setter TargetName="Box" Property="Background" Value="{StaticResource Ink}"/>
              <Setter TargetName="Mark" Property="Visibility" Value="Visible"/>
            </Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ScrollBar">
    <Setter Property="Width" Value="8"/>
    <Setter Property="MinWidth" Value="8"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ScrollBar">
          <Track x:Name="PART_Track" IsDirectionReversed="True">
            <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
              <Border Background="#BDB8AE" Margin="2,0"/>
            </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
          </Track>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
    <Style.Triggers>
      <Trigger Property="Orientation" Value="Horizontal">
        <Setter Property="Width" Value="Auto"/>
        <Setter Property="Height" Value="8"/>
        <Setter Property="MinHeight" Value="8"/>
        <Setter Property="Template">
          <Setter.Value>
            <ControlTemplate TargetType="ScrollBar">
              <Track x:Name="PART_Track">
                <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
                  <Border Background="#BDB8AE" Margin="0,2"/>
                </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
              </Track>
            </ControlTemplate>
          </Setter.Value>
        </Setter>
      </Trigger>
    </Style.Triggers>
  </Style>

  <!-- Inputs: underline only -->
  <Style TargetType="TextBox">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="BorderBrush" Value="{StaticResource Ink}"/>
    <Setter Property="BorderThickness" Value="0,0,0,1.5"/>
    <Setter Property="CaretBrush" Value="{StaticResource Ink}"/>
    <Setter Property="SelectionBrush" Value="{StaticResource Signal}"/>
    <Setter Property="Padding" Value="2,5"/>
    <Setter Property="FontSize" Value="13.5"/>
  </Style>

  <Style TargetType="ComboBox">
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="FontSize" Value="13.5"/>
    <Setter Property="MinWidth" Value="160"/>
    <Setter Property="Height" Value="32"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ComboBox">
          <Grid>
            <ToggleButton Focusable="False" ClickMode="Press"
                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
              <ToggleButton.Template>
                <ControlTemplate TargetType="ToggleButton">
                  <Border x:Name="Bd" Background="Transparent" BorderBrush="#141414" BorderThickness="0,0,0,1.5">
                    <Path HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,6,0" Data="M0,0 L4.5,4.5 L9,0"
                          Stroke="#141414" StrokeThickness="1.5"/>
                  </Border>
                  <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#E4E0D8"/></Trigger>
                  </ControlTemplate.Triggers>
                </ControlTemplate>
              </ToggleButton.Template>
            </ToggleButton>
            <ContentPresenter IsHitTestVisible="False" Margin="2,0,24,0" VerticalAlignment="Center"
                              Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"/>
            <Popup IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom" AllowsTransparency="False" Focusable="False">
              <Border Background="#F7F5F1" BorderBrush="#141414" BorderThickness="1" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="320">
                <ScrollViewer><ItemsPresenter/></ScrollViewer>
              </Border>
            </Popup>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style TargetType="ComboBoxItem">
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ComboBoxItem">
          <Border x:Name="Bd" Padding="10,6" Background="Transparent"><ContentPresenter/></Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="Bd" Property="Background" Value="#E4E0D8"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ListBox">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="0"/>
  </Style>

  <!-- Tables: hairline rows, small-caps header, soft signal selection -->
  <Style TargetType="DataGrid">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="BorderBrush" Value="{StaticResource Ink}"/>
    <Setter Property="BorderThickness" Value="0,1.5,0,1"/>
    <Setter Property="RowBackground" Value="Transparent"/>
    <Setter Property="AlternatingRowBackground" Value="Transparent"/>
    <Setter Property="GridLinesVisibility" Value="Horizontal"/>
    <Setter Property="HorizontalGridLinesBrush" Value="{StaticResource Rule}"/>
    <Setter Property="HeadersVisibility" Value="Column"/>
    <Setter Property="AutoGenerateColumns" Value="False"/>
    <Setter Property="IsReadOnly" Value="True"/>
    <Setter Property="CanUserAddRows" Value="False"/>
    <Setter Property="SelectionMode" Value="Extended"/>
    <Setter Property="SelectionUnit" Value="FullRow"/>
    <Setter Property="RowHeight" Value="32"/>
    <Setter Property="FontSize" Value="13"/>
  </Style>
  <Style TargetType="DataGridColumnHeader">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Foreground" Value="{StaticResource Ink3}"/>
    <Setter Property="FontFamily" Value="{StaticResource Display}"/>
    <Setter Property="FontSize" Value="12"/>
    <Setter Property="Padding" Value="8,8"/>
    <Setter Property="BorderBrush" Value="{StaticResource Rule}"/>
    <Setter Property="BorderThickness" Value="0,0,0,1"/>
  </Style>
  <Style TargetType="DataGridCell">
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Padding" Value="8,0"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="DataGridCell">
          <Border Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
            <ContentPresenter VerticalAlignment="Center"/>
          </Border>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
    <Style.Triggers>
      <Trigger Property="IsSelected" Value="True">
        <Setter Property="Background" Value="{StaticResource SignalSoft}"/>
        <Setter Property="Foreground" Value="{StaticResource Ink}"/>
      </Trigger>
    </Style.Triggers>
  </Style>

  <Style TargetType="ProgressBar">
    <Setter Property="Height" Value="4"/>
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ProgressBar">
          <Grid>
            <Border x:Name="PART_Track" Background="{StaticResource Rule}"/>
            <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}"/>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ToolTip">
    <Setter Property="Foreground" Value="{StaticResource Ink}"/>
    <Setter Property="HasDropShadow" Value="False"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ToolTip">
          <Border Background="#F7F5F1" BorderBrush="#141414" BorderThickness="1" Padding="14,12" MaxWidth="520">
            <ContentPresenter/>
          </Border>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
</ResourceDictionary>
'@

$Blob.GuiXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BLOB OPTIMIZER" Width="1280" Height="840" MinWidth="1000" MinHeight="640"
        WindowStartupLocation="CenterScreen" Background="#EFECE6" WindowStyle="None" ResizeMode="CanResize"
        FontFamily="Segoe UI" FontSize="13" UseLayoutRounding="True" TextOptions.TextFormattingMode="Display">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="48" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="0"/>
  </WindowChrome.WindowChrome>
  <!--THEME-->
  <Border x:Name="RootBorder" BorderBrush="#141414" BorderThickness="1">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="48"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="26"/>
      </Grid.RowDefinitions>

      <!-- Title bar -->
      <Border Grid.Row="0" BorderBrush="#141414" BorderThickness="0,0,0,1.5">
        <Grid>
          <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="22,0,0,0">
            <TextBlock Text="BLOB" FontFamily="{StaticResource Display}" FontWeight="Bold" FontSize="21" VerticalAlignment="Center"/>
            <Border Width="7" Height="7" Background="#FF4F00" Margin="3,9,0,0" VerticalAlignment="Center"/>
            <TextBlock Text="optimizer" FontFamily="{StaticResource Display}" FontSize="15" Foreground="#57544E" Margin="10,3,0,0" VerticalAlignment="Center"/>
            <TextBlock x:Name="TitleVersion" FontFamily="{StaticResource Mono}" FontSize="11" Foreground="#8A867E" Margin="12,5,0,0" VerticalAlignment="Center"/>
          </StackPanel>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <Border x:Name="DryRunBadge" BorderBrush="#B83A00" BorderThickness="1" Padding="7,1" Margin="0,0,10,0" VerticalAlignment="Center" Visibility="Collapsed">
              <TextBlock Text="DRY RUN" FontFamily="{StaticResource Display}" FontSize="11.5" Foreground="#B83A00"/>
            </Border>
            <Border x:Name="AdminBadge" BorderThickness="1" Padding="7,1" Margin="0,0,18,0" VerticalAlignment="Center">
              <TextBlock x:Name="AdminBadgeText" FontFamily="{StaticResource Display}" FontSize="11.5"/>
            </Border>
            <Button x:Name="BtnMin" Style="{StaticResource CaptionButton}" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Minimize">
              <Path Data="M0,0.5 L10,0.5" Stroke="#141414" StrokeThickness="1.2"/>
            </Button>
            <Button x:Name="BtnMax" Style="{StaticResource CaptionButton}" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Maximize">
              <Path Data="M0.5,0.5 H9.5 V9.5 H0.5 Z" Stroke="#141414" StrokeThickness="1.2"/>
            </Button>
            <Button x:Name="BtnClose" Style="{StaticResource CloseButton}" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Close">
              <Path x:Name="CloseGlyph" Data="M0,0 L10,10 M10,0 L0,10" Stroke="#141414" StrokeThickness="1.2"/>
            </Button>
          </StackPanel>
        </Grid>
      </Border>

      <!-- Body -->
      <Grid Grid.Row="1">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="220"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Table of contents -->
        <Border Grid.Column="0" BorderBrush="#141414" BorderThickness="0,0,1.5,0">
          <DockPanel>
            <TextBlock DockPanel.Dock="Top" Text="CONTENTS" FontFamily="{StaticResource Display}" FontSize="11.5" Foreground="#8A867E" Margin="22,22,0,10"/>
            <StackPanel DockPanel.Dock="Bottom" Margin="22,10,16,18">
              <TextBlock Text="Portable. Nothing installed." FontSize="11.5" Foreground="#8A867E"/>
              <TextBlock Text="Every change can be undone." FontSize="11.5" Foreground="#8A867E" Margin="0,2,0,0"/>
            </StackPanel>
            <ScrollViewer VerticalScrollBarVisibility="Auto">
              <StackPanel x:Name="NavPanel"/>
            </ScrollViewer>
          </DockPanel>
        </Border>

        <!-- Page -->
        <Grid Grid.Column="1">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Margin="40,26,36,0" BorderBrush="#141414" BorderThickness="0,0,0,2" Padding="0,0,0,14">
            <DockPanel>
              <StackPanel x:Name="PageActions" DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Bottom"/>
              <StackPanel>
                <StackPanel Orientation="Horizontal">
                  <TextBlock x:Name="PageNumber" FontFamily="{StaticResource Display}" FontSize="32" Foreground="#B8B3A9" Margin="0,0,14,0"/>
                  <TextBlock x:Name="PageTitle" FontFamily="{StaticResource Display}" FontSize="32" FontWeight="SemiBold"/>
                </StackPanel>
                <TextBlock x:Name="PageSubtitle" FontSize="13.5" Foreground="#57544E" Margin="0,4,0,0" MaxWidth="620" HorizontalAlignment="Left"/>
              </StackPanel>
            </DockPanel>
          </Border>
          <ScrollViewer x:Name="PageScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="40,20,36,28">
            <ContentControl x:Name="PageHost"/>
          </ScrollViewer>
          <!-- Pending changes bar (shown only when choices are waiting) -->
          <Border x:Name="PendingBar" Grid.Row="2" Background="#141414" Padding="40,12,36,12" Visibility="Collapsed">
            <DockPanel>
              <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
                <Button x:Name="PendingDiscard" Content="Discard" Foreground="#EFECE6" BorderBrush="#57544E" Padding="16,6"/>
                <Button x:Name="PendingApply" Content="Review and apply" Background="#FF4F00" BorderBrush="#FF4F00" Foreground="#141414" Padding="18,6" Margin="0"/>
              </StackPanel>
              <Border Width="9" Height="9" Background="#FF4F00" VerticalAlignment="Center" Margin="0,0,12,0"/>
              <TextBlock x:Name="PendingText" FontFamily="{StaticResource Display}" FontSize="15" Foreground="#EFECE6" VerticalAlignment="Center"/>
            </DockPanel>
          </Border>
        </Grid>
      </Grid>

      <!-- Log drawer -->
      <Border Grid.Row="2" BorderBrush="#141414" BorderThickness="0,1.5,0,0">
        <DockPanel>
          <DockPanel DockPanel.Dock="Top" Margin="22,5,12,5">
            <Button x:Name="BtnToggleLog" DockPanel.Dock="Right" Content="Show log" Style="{StaticResource ChipButton}" Margin="12,0,0,0"/>
            <Button x:Name="BtnClearLog" DockPanel.Dock="Right" Content="Clear" Style="{StaticResource ChipButton}" Margin="12,0,0,0"/>
            <TextBlock Text="LOG" FontFamily="{StaticResource Display}" FontSize="11.5" Foreground="#8A867E" VerticalAlignment="Center" Margin="0,0,14,0"/>
            <TextBlock x:Name="LogLast" FontFamily="{StaticResource Mono}" FontSize="11.5" Foreground="#57544E" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" TextWrapping="NoWrap"/>
          </DockPanel>
          <ScrollViewer x:Name="LogScroll" Height="130" VerticalScrollBarVisibility="Auto" Padding="22,2,12,8" Visibility="Collapsed">
            <StackPanel x:Name="LogPanel"/>
          </ScrollViewer>
        </DockPanel>
      </Border>

      <!-- Status line -->
      <Border Grid.Row="3" BorderBrush="#D6D2CA" BorderThickness="0,1,0,0">
        <DockPanel Margin="22,0">
          <TextBlock x:Name="StatusRight" DockPanel.Dock="Right" FontFamily="{StaticResource Mono}" Foreground="#8A867E" FontSize="11" VerticalAlignment="Center"/>
          <TextBlock x:Name="StatusText" FontFamily="{StaticResource Mono}" Foreground="#57544E" FontSize="11" VerticalAlignment="Center" Text="Ready"/>
        </DockPanel>
      </Border>
    </Grid>
  </Border>
</Window>
'@

$Blob.GuiDialogXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="740" Height="580" MinWidth="520" MinHeight="300" WindowStyle="None" ResizeMode="CanResize"
        WindowStartupLocation="CenterOwner" Background="#F7F5F1" ShowInTaskbar="False" FontFamily="Segoe UI" FontSize="13">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="64" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="0"/>
  </WindowChrome.WindowChrome>
  <!--THEME-->
  <Border x:Name="DlgBorder" BorderBrush="#141414" BorderThickness="1.5">
    <DockPanel>
      <Border x:Name="DlgStripe" DockPanel.Dock="Top" Height="5" Background="#141414"/>
      <Border DockPanel.Dock="Top" Padding="28,18,28,14" BorderBrush="#D6D2CA" BorderThickness="0,0,0,1">
        <StackPanel>
          <TextBlock x:Name="DlgTitle" FontFamily="{StaticResource Display}" FontSize="22" FontWeight="SemiBold"/>
          <TextBlock x:Name="DlgSub" FontSize="13" Foreground="#57544E" Margin="0,4,0,0"/>
        </StackPanel>
      </Border>
      <Border DockPanel.Dock="Bottom" Padding="28,14" BorderBrush="#141414" BorderThickness="0,1.5,0,0">
        <DockPanel>
          <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
            <Button x:Name="DlgCancel" Content="Cancel" MinWidth="96"/>
            <Button x:Name="DlgOk" Content="Confirm" MinWidth="130" Margin="0" Style="{StaticResource AccentButton}"/>
          </StackPanel>
          <CheckBox x:Name="DlgCheck" VerticalAlignment="Center" Margin="0,0,16,0" Visibility="Collapsed">
            <TextBlock x:Name="DlgCheckText" FontSize="13"/>
          </CheckBox>
        </DockPanel>
      </Border>
      <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="28,16">
        <StackPanel x:Name="DlgBody"/>
      </ScrollViewer>
    </DockPanel>
  </Border>
</Window>
'@
